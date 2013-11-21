"=============================================================================
" FILE: neosnippet.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 21 Nov 2013.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Global options definition. "{{{
call neosnippet#util#set_default(
      \ 'g:neosnippet#disable_runtime_snippets', {})
call neosnippet#util#set_default(
      \ 'g:neosnippet#snippets_directory', '')
call neosnippet#util#set_default(
      \ 'g:neosnippet#disable_select_mode_mappings', 1)
call neosnippet#util#set_default(
      \ 'g:neosnippet#enable_snipmate_compatibility', 0)
"}}}

function! neosnippet#expandable_or_jumpable() "{{{
  return neosnippet#mappings#expandable_or_jumpable()
endfunction"}}}
function! neosnippet#expandable() "{{{
  return neosnippet#mappings#expandable()
endfunction"}}}
function! neosnippet#jumpable() "{{{
  return neosnippet#mappings#jumpable()
endfunction"}}}

function! s:is_beginning_of_line(cur_text) "{{{
  let keyword_pattern = '\S\+'
  let cur_keyword_str = matchstr(a:cur_text, keyword_pattern.'$')
  let line_part = a:cur_text[: -1-len(cur_keyword_str)]
  let prev_word_end = matchend(line_part, keyword_pattern)

  return prev_word_end <= 0
endfunction"}}}
function! neosnippet#get_cursor_snippet(snippets, cur_text) "{{{
  let cur_word = matchstr(a:cur_text, '\S\+$')
  if cur_word != '' && has_key(a:snippets, cur_word)
      return cur_word
  endif

  while cur_word != ''
    if has_key(a:snippets, cur_word) &&
          \ a:snippets[cur_word].options.word
      return cur_word
    endif

    let cur_word = substitute(cur_word, '^\%(\w\+\|\W\)', '', '')
  endwhile

  return cur_word
endfunction"}}}

function! neosnippet#jump(cur_text, col) "{{{
  call s:skip_next_auto_completion()

  let expand_stack = neosnippet#variables#expand_stack()

  " Get patterns and count.
  if empty(expand_stack)
    return s:search_outof_range(a:col)
  endif

  let expand_info = expand_stack[-1]
  " Search patterns.
  let [begin, end] = neosnippet#_get_snippet_range(
        \ expand_info.begin_line,
        \ expand_info.begin_patterns,
        \ expand_info.end_line,
        \ expand_info.end_patterns)
  if neosnippet#_search_snippet_range(begin, end, expand_info.holder_cnt)
    " Next count.
    let expand_info.holder_cnt += 1
    return 1
  endif

  " Search placeholder 0.
  if neosnippet#_search_snippet_range(begin, end, 0)
    return 1
  endif

  " Not found.
  let expand_stack = neosnippet#variables#expand_stack()
  let expand_stack = expand_stack[: -2]

  return s:search_outof_range(a:col)
endfunction"}}}
function! neosnippet#expand(cur_text, col, trigger_name) "{{{
  call s:skip_next_auto_completion()

  let snippets = neosnippet#get_snippets()

  if a:trigger_name == '' || !has_key(snippets, a:trigger_name)
    let pos = getpos('.')
    let pos[2] = len(a:cur_text)+1
    call setpos('.', pos)

    if pos[2] < col('$')
      startinsert
    else
      startinsert!
    endif

    return
  endif

  let snippet = snippets[a:trigger_name]
  let cur_text = a:cur_text[: -1-len(a:trigger_name)]

  let snip_word = snippet.snip
  if snip_word =~ '\\\@<!`.*\\\@<!`'
    let snip_word = s:eval_snippet(snip_word)
  endif

  " Substitute escaped `.
  let snip_word = substitute(snip_word, '\\`', '`', 'g')

  " Substitute markers.
  let snip_word = substitute(snip_word,
        \ '\\\@<!'.neosnippet#get_placeholder_marker_substitute_pattern(),
        \ '<`\1`>', 'g')
  let snip_word = substitute(snip_word,
        \ '\\\@<!'.neosnippet#get_mirror_placeholder_marker_substitute_pattern(),
        \ '<|\1|>', 'g')
  let snip_word = substitute(snip_word,
        \ '\\'.neosnippet#get_mirror_placeholder_marker_substitute_pattern().'\|'.
        \ '\\'.neosnippet#get_placeholder_marker_substitute_pattern(),
        \ '\=submatch(0)[1:]', 'g')

  " Insert snippets.
  let next_line = getline('.')[a:col-1 :]
  let snippet_lines = split(snip_word, '\n', 1)
  if empty(snippet_lines)
    return
  endif

  let begin_line = line('.')
  let end_line = line('.') + len(snippet_lines) - 1

  let snippet_lines[0] = cur_text . snippet_lines[0]
  let next_col = len(snippet_lines[-1]) + 1
  let snippet_lines[-1] = snippet_lines[-1] . next_line

  if has('folding')
    " Note: Change foldmethod to "manual". Because, if you use foldmethod is
    " expr, whole snippet is visually selected.
    let foldmethod_save = &l:foldmethod
    let &l:foldmethod = 'manual'
  endif

  let expand_stack = neosnippet#variables#expand_stack()

  try
    call setline('.', snippet_lines[0])
    if len(snippet_lines) > 1
      call append('.', snippet_lines[1:])
    endif

    if begin_line != end_line || snippet.options.indent
      call s:indent_snippet(begin_line, end_line)
    endif

    let begin_patterns = (begin_line > 1) ?
          \ [getline(begin_line - 1)] : []
    let end_patterns =  (end_line < line('$')) ?
          \ [getline(end_line + 1)] : []
    call add(expand_stack, {
          \ 'begin_line' : begin_line,
          \ 'begin_patterns' : begin_patterns,
          \ 'end_line' : end_line,
          \ 'end_patterns' : end_patterns,
          \ 'holder_cnt' : 1,
          \ })

    if snip_word =~ neosnippet#get_placeholder_marker_pattern()
      call neosnippet#jump(a:cur_text, a:col)
    endif
  finally
    if has('folding')
      if foldmethod_save !=# &l:foldmethod
        let &l:foldmethod = foldmethod_save
      endif

      silent! execute begin_line . ',' . end_line . 'foldopen!'
    endif
  endtry

  let &l:iminsert = 0
  let &l:imsearch = 0
endfunction"}}}
function! neosnippet#expand_target() "{{{
  let trigger = input('Please input snippet trigger: ',
        \ '', 'customlist,neosnippet#complete_target_snippets')
  let neosnippet = neosnippet#variables#current_neosnippet()
  if !has_key(neosnippet#get_snippets(), trigger) ||
        \ neosnippet#get_snippets()[trigger].snip !~#
        \   neosnippet#get_placeholder_target_marker_pattern()
    if trigger != ''
      echo 'The trigger is invalid.'
    endif

    let neosnippet.target = ''
    return
  endif

  call neosnippet#expand_target_trigger(trigger)
endfunction"}}}
function! neosnippet#expand_target_trigger(trigger) "{{{
  let neosnippet = neosnippet#variables#current_neosnippet()
  let neosnippet.target = substitute(
        \ neosnippet#get_selected_text(visualmode(), 1), '\n$', '', '')

  let line = getpos("'<")[1]
  let col = getpos("'<")[2]

  call neosnippet#delete_selected_text(visualmode())

  call cursor(line, col)

  call neosnippet#expand(neosnippet#util#get_cur_text(), col, a:trigger)
endfunction"}}}
function! s:indent_snippet(begin, end) "{{{
  if a:begin > a:end
    return
  endif

  let pos = getpos('.')

  let neosnippet = neosnippet#variables#current_neosnippet()

  let equalprg = &l:equalprg
  try
    setlocal equalprg=

    " Indent begin line?
    let begin = (neosnippet.target == '') ? a:begin : a:begin + 1

    let base_indent = matchstr(getline(a:begin), '^\s\+')
    for line_nr in range(begin, a:end)
      call cursor(line_nr, 0)

      if getline('.') =~ '^\t\+'
        " Delete head tab character.
        let current_line = substitute(getline('.'), '^\t', '', '')

        if &l:expandtab && current_line =~ '^\t\+'
          " Expand tab.
          cal setline('.', substitute(current_line,
                \ '^\t\+', base_indent . repeat(' ', &shiftwidth *
                \    len(matchstr(current_line, '^\t\+'))), ''))
        elseif line_nr != a:begin
          call setline('.', base_indent . current_line)
        endif
      else
        silent normal! ==
      endif
    endfor
  finally
    let &l:equalprg = equalprg
    call setpos('.', pos)
  endtry
endfunction"}}}

function! neosnippet#_get_snippet_range(begin_line, begin_patterns, end_line, end_patterns) "{{{
  let pos = getpos('.')

  call cursor(a:begin_line, 0)
  if empty(a:begin_patterns)
    let begin = line('.') - 50
  else
    let [begin, _] = searchpos('^' . neosnippet#util#escape_pattern(
          \ a:begin_patterns[0]) . '$', 'bnW')
    if begin <= 0
      let begin = line('.') - 50
    endif
  endif
  if begin <= 0
    let begin = 1
  endif

  call cursor(a:end_line, 0)
  if empty(a:end_patterns)
    let end = line('.') + 50
  else
    let [end, _] = searchpos('^' . neosnippet#util#escape_pattern(
          \ a:end_patterns[0]) . '$', 'nW')
    if end <= 0
      let end = line('.') + 50
    endif
  endif
  if end > line('$')
    let end = line('$')
  endif

  call setpos('.', pos)
  return [begin, end]
endfunction"}}}
function! neosnippet#_search_snippet_range(start, end, cnt, ...) "{{{
  let is_select = get(a:000, 0, 1)
  call s:substitute_placeholder_marker(a:start, a:end, a:cnt)

  " Search marker pattern.
  let pattern = substitute(neosnippet#get_placeholder_marker_pattern(),
        \ '\\d\\+', a:cnt, '')

  for line in filter(range(a:start, a:end),
        \ 'getline(v:val) =~ pattern')
    call s:expand_placeholder(a:start, a:end, a:cnt, line, is_select)
    return 1
  endfor

  return 0
endfunction"}}}
function! s:search_outof_range(col) "{{{
  call s:substitute_placeholder_marker(1, 0, 0)

  let pattern = neosnippet#get_placeholder_marker_pattern()
  if search(pattern, 'w') > 0
    call s:expand_placeholder(line('.'), 0, '\\d\\+', line('.'))
    return 1
  endif

  let pos = getpos('.')
  if a:col == 1
    let pos[2] = 1
    call setpos('.', pos)
    startinsert
  elseif a:col >= col('$')
    startinsert!
  else
    let pos[2] = a:col+1
    call setpos('.', pos)
    startinsert
  endif

  " Not found.
  return 0
endfunction"}}}
function! s:expand_placeholder(start, end, holder_cnt, line, ...) "{{{
  let is_select = get(a:000, 0, 1)

  let pattern = substitute(neosnippet#get_placeholder_marker_pattern(),
        \ '\\d\\+', a:holder_cnt, '')
  let current_line = getline(a:line)
  let match = match(current_line, pattern)
  let neosnippet = neosnippet#variables#current_neosnippet()

  let default_pattern = substitute(
        \ neosnippet#get_placeholder_marker_default_pattern(),
        \ '\\d\\+', a:holder_cnt, '')
  let default = substitute(
        \ matchstr(current_line, default_pattern),
        \ '\\\ze[^\\]', '', 'g')

  if default =~ '^TARGET\>' && neosnippet.target != ''
    let default = ''
    let is_target = 1
  else
    let is_target = 0
  endif

  let default = substitute(default, '^TARGET:\?', '', '')

  let neosnippet.selected_text = default

  " Substitute marker.
  let default = substitute(default,
        \ neosnippet#get_placeholder_marker_substitute_pattern(),
        \ '<`\1`>', 'g')
  let default = substitute(default,
        \ neosnippet#get_mirror_placeholder_marker_substitute_pattern(),
        \ '<|\1|>', 'g')

  " len() cannot use for multibyte.
  let default_len = len(substitute(default, '.', 'x', 'g'))

  let pos = getpos('.')
  let pos[1] = a:line
  let pos[2] = match+1

  let cnt = s:search_sync_placeholder(a:start, a:end, a:holder_cnt)
  if cnt >= 0
    let pattern = substitute(neosnippet#get_placeholder_marker_pattern(),
          \ '\\d\\+', cnt, '')
    call setline(a:line, substitute(current_line, pattern,
          \ '<{'.cnt.':'.escape(default, '\').'}>', ''))
    let pos[2] += len('<{'.cnt.':')
  else
    " Substitute holder.
    call setline(a:line,
          \ substitute(current_line, pattern, escape(default, '\'), ''))
  endif

  call setpos('.', pos)

  if is_target
    " Expand target
    return s:expand_target_placeholder(a:line, match+1)
  endif

  if default_len > 0 && is_select
    " Select default value.
    let len = default_len-1
    if &l:selection == 'exclusive'
      let len += 1
    endif

    stopinsert
    execute 'normal! v'. repeat('l', len) . "\<C-g>"
  elseif pos[2] < col('$')
    startinsert
  else
    startinsert!
  endif
endfunction"}}}
function! s:expand_target_placeholder(line, col) "{{{
  " Expand target
  let neosnippet = neosnippet#variables#current_neosnippet()
  let next_line = getline(a:line)[a:col-1 :]
  let target_lines = split(neosnippet.target, '\n', 1)

  let cur_text = getline(a:line)[: a:col-2]
  let target_lines[0] = cur_text . target_lines[0]
  let next_col = len(target_lines[-1]) + 1
  let target_lines[-1] = target_lines[-1] . next_line

  let begin_line = a:line
  let end_line = a:line + len(target_lines) - 1

  let col = col('.')
  try
    let base_indent = matchstr(cur_text, '^\s\+')
    call setline(a:line, target_lines[0])
    if len(target_lines) > 1
      call append(a:line, map(target_lines[1:],
            \ 'base_indent . v:val'))
    endif

    call cursor(end_line, 0)

    if next_line != ''
      startinsert
      let col = col('.')
    else
      startinsert!
      let col = col('$')
    endif
  finally
    if has('folding')
      silent! execute begin_line . ',' . end_line . 'foldopen!'
    endif
  endtry

  let neosnippet.target = ''

  call neosnippet#jump(neosnippet#util#get_cur_text(), col)
endfunction"}}}
function! s:search_sync_placeholder(start, end, number) "{{{
  if a:end == 0
    " Search in current buffer.
    let cnt = matchstr(getline('.'),
          \ substitute(neosnippet#get_placeholder_marker_pattern(),
          \ '\\d\\+', '\\zs\\d\\+\\ze', ''))
    return search(substitute(
          \ neosnippet#get_mirror_placeholder_marker_pattern(),
          \ '\\d\\+', cnt, ''), 'nw') > 0 ? cnt : -1
  endif

  let pattern = substitute(
          \ neosnippet#get_mirror_placeholder_marker_pattern(),
          \ '\\d\\+', a:number, '')
  for line in filter(range(a:start, a:end),
        \ 'getline(v:val) =~ pattern')
    return a:number
  endfor

  return -1
endfunction"}}}
function! s:substitute_placeholder_marker(start, end, snippet_holder_cnt) "{{{
  if a:snippet_holder_cnt > 0
    let cnt = a:snippet_holder_cnt-1
    let sync_marker = substitute(neosnippet#get_sync_placeholder_marker_pattern(),
        \ '\\d\\+', cnt, '')
    let mirror_marker = substitute(
          \ neosnippet#get_mirror_placeholder_marker_pattern(),
          \ '\\d\\+', cnt, '')
    let line = a:start

    for line in range(a:start, a:end)
      if getline(line) =~ sync_marker
        let sub = escape(matchstr(getline(line),
              \ substitute(neosnippet#get_sync_placeholder_marker_default_pattern(),
              \ '\\d\\+', cnt, '')), '/\')
        silent execute printf('%d,%ds/\m' . mirror_marker . '/%s/'
          \ . (&gdefault ? '' : 'g'), a:start, a:end, sub)
        call setline(line, substitute(getline(line), sync_marker, sub, ''))
      endif
    endfor
  elseif search(neosnippet#get_sync_placeholder_marker_pattern(), 'wb') > 0
    let sub = escape(matchstr(getline('.'),
          \ neosnippet#get_sync_placeholder_marker_default_pattern()), '/\')
    let cnt = matchstr(getline('.'),
          \ substitute(neosnippet#get_sync_placeholder_marker_pattern(),
          \ '\\d\\+', '\\zs\\d\\+\\ze', ''))
    let mirror_marker = substitute(
          \ neosnippet#get_mirror_placeholder_marker_pattern(),
          \ '\\d\\+', cnt, '')
    silent execute printf('%%s/\m' . mirror_marker . '/%s/'
          \ . (&gdefault ? 'g' : ''), sub)
    let sync_marker = substitute(neosnippet#get_sync_placeholder_marker_pattern(),
        \ '\\d\\+', cnt, '')
    call setline('.', substitute(getline('.'), sync_marker, sub, ''))
  endif
endfunction"}}}
function! s:eval_snippet(snippet_text) "{{{
  let snip_word = ''
  let prev_match = 0
  let match = match(a:snippet_text, '\\\@<!`.\{-}\\\@<!`')

  while match >= 0
    if match - prev_match > 0
      let snip_word .= a:snippet_text[prev_match : match - 1]
    endif
    let prev_match = matchend(a:snippet_text,
          \ '\\\@<!`.\{-}\\\@<!`', match)
    let snip_word .= eval(
          \ a:snippet_text[match+1 : prev_match - 2])

    let match = match(a:snippet_text, '\\\@<!`.\{-}\\\@<!`', prev_match)
  endwhile
  if prev_match >= 0
    let snip_word .= a:snippet_text[prev_match :]
  endif

  return snip_word
endfunction"}}}
function! neosnippet#variables#current_neosnippet() "{{{
  if !exists('b:neosnippet')
    let b:neosnippet = {
          \ 'snippets' : {},
          \ 'selected_text' : '',
          \ 'target' : '',
          \ 'trigger' : 0,
          \}
  endif

  return b:neosnippet
endfunction"}}}
function! neosnippet#get_snippets() "{{{
  call neosnippet#init#check()

  let neosnippet = neosnippet#variables#current_neosnippet()
  let snippets = copy(neosnippet.snippets)
  for filetype in s:get_sources_filetypes(neosnippet#get_filetype())
    call neosnippet#commands#_make_cache(filetype)
    call extend(snippets,
          \ neosnippet#variables#snippets()[filetype], 'keep')
  endfor

  let cur_text = neosnippet#util#get_cur_text()

  if mode() ==# 'i'
    " Special filters.
    if !s:is_beginning_of_line(cur_text)
      call filter(snippets, '!v:val.options.head')
    endif
  endif

  call filter(snippets, "cur_text =~# get(v:val, 'regexp', '')")

  return snippets
endfunction"}}}
function! neosnippet#get_snippets_directory() "{{{
  let snippets_dir = copy(neosnippet#variables#snippets_dir())
  if !get(g:neosnippet#disable_runtime_snippets,
        \ neosnippet#get_filetype(),
        \ get(g:neosnippet#disable_runtime_snippets, '_', 0))
    let snippets_dir += neosnippet#variables#runtime_dir()
  endif

  return snippets_dir
endfunction"}}}
function! neosnippet#get_user_snippets_directory() "{{{
  return copy(neosnippet#variables#snippets_dir())
endfunction"}}}
function! neosnippet#get_runtime_snippets_directory() "{{{
  return copy(neosnippet#variables#runtime_dir())
endfunction"}}}
function! neosnippet#get_filetype() "{{{
  if !exists('s:exists_context_filetype')
    " context_filetype.vim installation check.
    try
      call context_filetype#version()
      let s:exists_context_filetype = 1
    catch
      let s:exists_context_filetype = 0
    endtry
  endif

  let context_filetype =
        \ s:exists_context_filetype ?
        \ context_filetype#get_filetype() : &filetype
  if context_filetype == ''
    let context_filetype = 'nothing'
  endif

  return context_filetype
endfunction"}}}
function! s:get_sources_filetypes(filetype) "{{{
  let filetypes =
        \ exists('*neocomplete#get_source_filetypes') ?
        \   neocomplete#get_source_filetypes(a:filetype) :
        \ exists('*neocomplcache#get_source_filetypes') ?
        \   neocomplcache#get_source_filetypes(a:filetype) :
        \   [(a:filetype == '') ? 'nothing' : a:filetype]
  return filetypes + ['_']
endfunction"}}}

" Complete filetype helper.
function! neosnippet#filetype_complete(arglead, cmdline, cursorpos) "{{{
  " Dup check.
  let ret = {}
  for item in map(
        \ split(globpath(&runtimepath, 'syntax/*.vim'), '\n') +
        \ split(globpath(&runtimepath, 'indent/*.vim'), '\n') +
        \ split(globpath(&runtimepath, 'ftplugin/*.vim'), '\n')
        \ , 'fnamemodify(v:val, ":t:r")')
    if !has_key(ret, item) && item =~ '^'.a:arglead
      let ret[item] = 1
    endif
  endfor

  return sort(keys(ret))
endfunction"}}}
function! neosnippet#complete_target_snippets(arglead, cmdline, cursorpos) "{{{
  return map(filter(values(neosnippet#get_snippets()),
        \ "stridx(v:val.word, a:arglead) == 0
        \ && v:val.snip =~# neosnippet#get_placeholder_target_marker_pattern()"), 'v:val.word')
endfunction"}}}

" Get marker patterns.
function! neosnippet#get_placeholder_target_marker_pattern() "{{{
  return '\${\d\+:TARGET\%(:.\{-}\)\?\\\@<!}'
endfunction"}}}
function! neosnippet#get_placeholder_marker_pattern() "{{{
  return '<`\d\+\%(:.\{-}\)\?\\\@<!`>'
endfunction"}}}
function! neosnippet#get_placeholder_marker_substitute_pattern() "{{{
  return '\${\(\d\+\%(:.\{-}\)\?\\\@<!\)}'
endfunction"}}}
function! neosnippet#get_placeholder_marker_default_pattern() "{{{
  return '<`\d\+:\zs.\{-}\ze\\\@<!`>'
endfunction"}}}
function! neosnippet#get_sync_placeholder_marker_pattern() "{{{
  return '<{\d\+\%(:.\{-}\)\?\\\@<!}>'
endfunction"}}}
function! neosnippet#get_sync_placeholder_marker_default_pattern() "{{{
  return '<{\d\+:\zs.\{-}\ze\\\@<!}>'
endfunction"}}}
function! neosnippet#get_mirror_placeholder_marker_pattern() "{{{
  return '<|\d\+|>'
endfunction"}}}
function! neosnippet#get_mirror_placeholder_marker_substitute_pattern() "{{{
  return '\$\(\d\+\)'
endfunction"}}}

function! neosnippet#get_selected_text(type, ...) "{{{
  let sel_save = &selection
  let &selection = 'inclusive'
  let reg_save = @@
  let pos = getpos('.')

  try
    " Invoked from Visual mode, use '< and '> marks.
    if a:0
      silent exe "normal! `<" . a:type . "`>y"
    elseif a:type == 'line'
      silent exe "normal! '[V']y"
    elseif a:type == 'block'
      silent exe "normal! `[\<C-v>`]y"
    else
      silent exe "normal! `[v`]y"
    endif

    return @@
  finally
    let &selection = sel_save
    let @@ = reg_save
    call setpos('.', pos)
  endtry
endfunction"}}}
function! neosnippet#delete_selected_text(type, ...) "{{{
  let sel_save = &selection
  let &selection = 'inclusive'
  let reg_save = @@
  let pos = getpos('.')

  try
    " Invoked from Visual mode, use '< and '> marks.
    if a:0
      silent exe "normal! `<" . a:type . "`>d"
    elseif a:type ==# 'V'
      silent exe "normal! `[V`]s"
    elseif a:type ==# "\<C-v>"
      silent exe "normal! `[\<C-v>`]d"
    else
      silent exe "normal! `[v`]d"
    endif
  finally
    let &selection = sel_save
    let @@ = reg_save
    call setpos('.', pos)
  endtry
endfunction"}}}
function! neosnippet#substitute_selected_text(type, text) "{{{
  let sel_save = &selection
  let &selection = 'inclusive'
  let reg_save = @@
  let pos = getpos('.')

  try
    " Invoked from Visual mode, use '< and '> marks.
    if a:0
      silent exe "normal! `<" . a:type . "`>s" . a:text
    elseif a:type ==# 'V'
      silent exe "normal! '[V']hs" . a:text
    elseif a:type ==# "\<C-v>"
      silent exe "normal! `[\<C-v>`]s" . a:text
    else
      silent exe "normal! `[v`]s" . a:text
    endif
  finally
    let &selection = sel_save
    let @@ = reg_save
    call setpos('.', pos)
  endtry
endfunction"}}}

function! s:skip_next_auto_completion() "{{{
  " Skip next auto completion.
  if exists('*neocomplcache#skip_next_complete')
    call neocomplcache#skip_next_complete()
  endif
  if exists('*neocomplete#skip_next_complete')
    call neocomplete#skip_next_complete()
  endif

  let neosnippet = neosnippet#variables#current_neosnippet()
  let neosnippet.trigger = 0
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
