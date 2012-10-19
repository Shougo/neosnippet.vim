"=============================================================================
" FILE: neosnippet.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 Oct 2012.
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

" Global options definition."{{{
call neosnippet#util#set_default(
      \ 'g:neosnippet#disable_runtime_snippets', {})
call neosnippet#util#set_default(
      \ 'g:neosnippet#snippets_directory',
      \ '', 'g:neocomplcache_snippets_dir')
call neosnippet#util#set_default(
      \ 'g:neosnippet#disable_select_mode_mappings',
      \ 0, 'g:neocomplcache_disable_select_mode_mappings')
"}}}

" Variables  "{{{
let s:neosnippet_options = [
      \ '-runtime',
      \ '-vertical', '-horizontal', '-direction=', '-split',
      \]
"}}}

function! s:initialize()"{{{
  " Initialize.
  let s:snippets_expand_stack = []

  if get(g:, 'neocomplcache_snippets_disable_runtime_snippets', 0)
    " Set for backward compatibility.
    let g:neosnippet#disable_runtime_snippets._ = 1
  endif

  " Set runtime dir.
  let s:runtime_dir = split(globpath(&runtimepath,
        \ 'autoload/neosnippet/snippets'), '\n')
  let s:runtime_dir += (exists('g:snippets_dir') ?
        \ split(g:snippets_dir, '\s*,\s*')
        \ : split(globpath(&runtimepath, 'snippets'), '\n'))
  call map(s:runtime_dir, 'substitute(v:val, "[\\\\/]$", "", "")')

  " Set snippets_dir.
  let s:snippets_dir = []
  for dir in split(g:neosnippet#snippets_directory, '\s*,\s*')
    let dir = neosnippet#util#expand(dir)
    if !isdirectory(dir)
      call mkdir(dir, 'p')
    endif
    call add(s:snippets_dir, dir)
  endfor
  call map(s:snippets_dir, 'substitute(v:val, "[\\\\/]$", "", "")')

  if has('conceal')
    " Supported conceal features.
    augroup neosnippet
      autocmd BufNewFile,BufRead,ColorScheme *
            \ syn match   neosnippetExpandSnippets
            \ '<`\d\+:\|`>\|<{\d\+:\|}>' conceal
      autocmd BufNewFile,BufRead,ColorScheme *
            \ execute 'syn match   neosnippetExpandSnippets'
            \  '''<`\d\+\\\@<!`>\|<{\d\+\\\@<!}>\|'
            \ .s:get_mirror_placeholder_marker_pattern()."'"
            \ 'conceal cchar=$'
    augroup END
  else
    augroup neosnippet
      autocmd BufNewFile,BufRead,ColorScheme *
            \ execute 'syn match   neosnippetExpandSnippets'
            \  "'".s:get_placeholder_marker_pattern(). '\|'
            \ .s:get_sync_placeholder_marker_pattern().'\|'
            \ .s:get_mirror_placeholder_marker_pattern()."'"
    augroup END
  endif

  hi def link neosnippetExpandSnippets Special

  " Select mode mappings."{{{
  if g:neosnippet#disable_select_mode_mappings
    snoremap <CR>     a<BS>
    snoremap <BS> a<BS>
    snoremap <right> <ESC>a
    snoremap <left> <ESC>bi
    snoremap ' a<BS>'
    snoremap ` a<BS>`
    snoremap % a<BS>%
    snoremap U a<BS>U
    snoremap ^ a<BS>^
    snoremap \ a<BS>\
    snoremap <C-x> a<BS><c-x>
  endif"}}}

  " Caching _ snippets.
  call neosnippet#make_cache('_')

  " Initialize check.
  call neosnippet#caching()

  if get(g:, 'loaded_echodoc', 0)
    call echodoc#register('snippets_complete', s:doc_dict)
  endif
endfunction"}}}

" For echodoc."{{{
let s:doc_dict = {
      \ 'name' : 'neosnippet',
      \ 'rank' : 100,
      \ 'filetypes' : {},
      \ }
function! s:doc_dict.search(cur_text)"{{{
  if mode() !=# 'i'
    return []
  endif

  let snippets = neosnippet#get_snippets()

  let cur_word = s:get_cursor_snippet(snippets, a:cur_text)
  if cur_word == ''
    return []
  endif

  let snip = snippets[cur_word]
  let ret = []
  call add(ret, { 'text' : snip.word, 'highlight' : 'String' })
  call add(ret, { 'text' : ' ' })
  call add(ret, { 'text' : snip.menu, 'highlight' : 'Special' })

  return ret
endfunction"}}}
"}}}

function! neosnippet#expandable()"{{{
  let ret = 0

  let snippets = neosnippet#get_snippets()
  let cur_text = neosnippet#util#get_cur_text()

  " Check snippet trigger.
  if s:get_cursor_snippet(snippets, cur_text) != ''
    let ret += 1
  endif

  " Check jumpable.
  if neosnippet#jumpable()
    let ret += 2
  endif

  return ret
endfunction"}}}
function! neosnippet#jumpable()"{{{
  " Found snippet placeholder.
  return search(s:get_placeholder_marker_pattern(). '\|'
            \ .s:get_sync_placeholder_marker_pattern(), 'nw') > 0
endfunction"}}}

function! neosnippet#caching()"{{{
  call neosnippet#make_cache(&filetype)
endfunction"}}}

function! neosnippet#recaching()"{{{
  let s:snippets = {}
endfunction"}}}

function! s:set_snippet_dict(snippet_pattern, snippet_dict, dup_check, snippets_file)"{{{
  if !has_key(a:snippet_pattern, 'name')
    return
  endif

  let pattern = s:set_snippet_pattern(a:snippet_pattern)
  let action_pattern = '^snippet\s\+' . a:snippet_pattern.name . '$'
  let a:snippet_dict[a:snippet_pattern.name] = pattern
  let a:dup_check[a:snippet_pattern.name] = 1

  for alias in get(a:snippet_pattern, 'alias', [])
    let alias_pattern = copy(pattern)
    let alias_pattern.word = alias

    let alias_pattern.action__path = a:snippets_file
    let alias_pattern.action__pattern = action_pattern
    let alias_pattern.real_name = a:snippet_pattern.name

    let a:snippet_dict[alias] = alias_pattern
    let a:dup_check[alias] = 1
  endfor

  let snippet = a:snippet_dict[a:snippet_pattern.name]
  let snippet.action__path = a:snippets_file
  let snippet.action__pattern = action_pattern
  let snippet.real_name = a:snippet_pattern.name
endfunction"}}}
function! s:set_snippet_pattern(dict)"{{{
  let a:dict.word = substitute(a:dict.word, '\n$', '', '')
  let menu_pattern = (a:dict.word =~
        \ s:get_placeholder_marker_substitute_pattern()
        \ . '.*' . s:get_placeholder_marker_substitute_pattern()) ?
        \ '<Snip> ' : '[Snip] '

  let abbr = get(a:dict, 'abbr', substitute(a:dict.word,
        \   s:get_placeholder_marker_pattern(). '\|'.
        \   s:get_mirror_placeholder_marker_pattern().
        \   '\|\s\+\|\n', ' ', 'g'))

  let dict = {
        \ 'word' : a:dict.name, 'snip' : a:dict.word,
        \ 'description' : a:dict.word,
        \ 'menu' : menu_pattern.abbr,
        \ 'dup' : 1, 'is_head' : get(a:dict, 'is_head', 0),
        \}
  return dict
endfunction"}}}

function! neosnippet#edit_snippets(args)"{{{
  let [args, options] = neosnippet#util#parse_options(
        \ a:args, s:neosnippet_options)

  let filetype = get(args, 0, '')
  if filetype == ''
    let filetype = neosnippet#get_filetype()
  endif

  let options = s:initialize_options(options)

  if options.runtime && empty(s:runtime_dir)
        \ || !options.runtime && empty(s:snippets_dir)
    return
  endif

  " Edit snippet file.
  let snippet_dir = (options.runtime ? s:runtime_dir[0] : s:snippets_dir[-1])
  let filename = snippet_dir .'/'.filetype

  if isdirectory(filename)
    " Edit in snippet directory.
    let filename .= '/'.filetype
  endif

  if filename !~ '\.snip*$'
    let filename .= '.snip'
  endif

  if options.split
    " Split window.
    execute options.direction
          \ (options.vertical ? 'vnew' : 'new')
  endif

  try
    edit `=filename`
  catch /^Vim\%((\a\+)\)\=:E749/
  endtry
endfunction"}}}

function! s:initialize_options(options)"{{{
  let default_options = {
        \ 'runtime' : 0,
        \ 'vertical' : 0,
        \ 'direction' : 'below',
        \ 'split' : 0,
        \ }

  let options = extend(default_options, a:options)

  " Complex initializer.
  if has_key(options, 'horizontal')
    " Disable vertically.
    let options.vertical = 0
  endif

  return options
endfunction"}}}

function! neosnippet#make_cache(filetype)"{{{
  let filetype = a:filetype == '' ?
        \ &filetype : a:filetype
  if filetype ==# ''
    let filetype = 'nothing'
  endif

  if has_key(s:snippets, filetype)
    return
  endif

  let snippets_dir = neosnippet#get_snippets_directory()
  let snippet = {}
  let snippets_files =
        \   split(globpath(join(snippets_dir, ','),
        \   filetype .  '.snip*'), '\n')
        \ + split(globpath(join(snippets_dir, ','),
        \   filetype .  '_*.snip*'), '\n')
        \ + split(globpath(join(snippets_dir, ','),
        \   filetype .  '/**/*.snip*'), '\n')
  for snippets_file in reverse(snippets_files)
    call s:load_snippets(snippet, snippets_file)
  endfor

  let s:snippets[filetype] = snippet
endfunction"}}}

function! s:load_snippets(snippet, snippets_file)"{{{
  let dup_check = {}
  let snippet_pattern = { 'word' : '' }

  let linenr = 1

  for line in readfile(a:snippets_file)
    if line =~ '^\h\w*.*\s$'
      " Delete spaces.
      let line = substitute(line, '\s\+$', '', '')
    endif

    if line =~ '^include'
      " Include snippets.
      let snippet_file = matchstr(line, '^include\s\+\zs.*$')

      for snippets_file in split(globpath(join(
            \ neosnippet#get_snippets_directory(), ','),
            \ snippet_file), '\n')
        call s:load_snippets(a:snippet, snippets_file)
      endfor
    elseif line =~ '^delete\s'
      let name = matchstr(line, '^delete\s\+\zs.*$')
      if name != '' && has_key(a:snippet, name)
        call filter(a:snippet, 'v:val.real_name !=# name')
      endif
    elseif line =~ '^snippet\s'
      if has_key(snippet_pattern, 'name')
        " Set previous snippet.
        call s:set_snippet_dict(snippet_pattern,
              \ a:snippet, dup_check, a:snippets_file)
        let snippet_pattern = { 'word' : '' }
      endif

      let snippet_pattern.name =
            \ substitute(matchstr(line, '^snippet\s\+\zs.*$'),
            \     '\s', '_', 'g')

      " Check for duplicated names.
      if has_key(dup_check, snippet_pattern.name)
        call neosnippet#util#print_error(
              \ 'Warning: ' . a:snippets_file . ':'
              \ . linenr . ': duplicated snippet name `'
              \ . snippet_pattern.name . '`')
        call neosnippet#util#print_error(
              \ 'Please delete this snippet name before.')
      endif
    elseif has_key(snippet_pattern, 'name')
      " Only in snippets.
      if line =~ '^abbr\s'
        let snippet_pattern.abbr = matchstr(line, '^abbr\s\+\zs.*$')
      elseif line =~ '^alias\s'
        let snippet_pattern.alias = split(matchstr(line,
              \ '^alias\s\+\zs.*$'), '[,[:space:]]\+')
      elseif line =~ '^prev_word\s'
        let prev_word = matchstr(line,
              \ '^prev_word\s\+[''"]\zs.*\ze[''"]$')
        if prev_word == '^'
          " For backward compatibility.
          let snippet_pattern.is_head = 1
        endif
      elseif line =~ '^\s'
        if snippet_pattern.word != ''
          let snippet_pattern.word .= "\n"
        else
          " Substitute Tab character.
          let line = substitute(line, '^\t', '', '')
        endif

        let snippet_pattern.word .=
                \ matchstr(line, '^ *\zs.*$')
      elseif line =~ '^$'
        " Blank line.
        let snippet_pattern.word .= "\n"
      endif
    endif

    let linenr += 1
  endfor

  if snippet_pattern.word !~
        \ s:get_placeholder_marker_substitute_pattern()
    " Add placeholder.
    let snippet_pattern.word .= '${0}'
  endif

  " Set previous snippet.
  call s:set_snippet_dict(snippet_pattern,
        \ a:snippet, dup_check, a:snippets_file)

  return a:snippet
endfunction"}}}

function! s:is_beginning_of_line(cur_text)"{{{
  let keyword_pattern = '\S\+'
  let cur_keyword_str = matchstr(a:cur_text, keyword_pattern.'$')
  let line_part = a:cur_text[: -1-len(cur_keyword_str)]
  let prev_word_end = matchend(line_part, keyword_pattern)

  return prev_word_end <= 0
endfunction"}}}
function! s:get_cursor_snippet(snippets, cur_text)"{{{
  let cur_word = matchstr(a:cur_text, '\S\+$')

  return has_key(a:snippets, cur_word) ? cur_word : ''
endfunction"}}}
function! s:snippets_expand(cur_text, col)"{{{
  let cur_word = s:get_cursor_snippet(
        \ neosnippet#get_snippets(),
        \ a:cur_text)

  call neosnippet#expand(
        \ a:cur_text, a:col, cur_word)
endfunction"}}}
function! s:snippets_jump(cur_text, col)"{{{
  " Get patterns and count.
  if empty(s:snippets_expand_stack)
    return s:search_outof_range(a:col)
  endif

  let expand_info = s:snippets_expand_stack[-1]
  " Search patterns.
  let [begin, end] = s:get_snippet_range(
        \ expand_info.begin_line,
        \ expand_info.begin_patterns,
        \ expand_info.end_line,
        \ expand_info.end_patterns)
  if s:search_snippet_range(begin, end, expand_info.holder_cnt)
    " Next count.
    let expand_info.holder_cnt += 1
    return 1
  endif

  " Search placeholder 0.
  if s:search_snippet_range(begin, end, 0)
    return 1
  endif

  " Not found.
  let s:snippets_expand_stack = s:snippets_expand_stack[: -2]

  return s:search_outof_range(a:col)
endfunction"}}}
function! s:snippets_expand_or_jump(cur_text, col)"{{{
  let cur_word = s:get_cursor_snippet(
        \ neosnippet#get_snippets(), a:cur_text)

  if cur_word != ''
    " Found snippet trigger.
    call neosnippet#expand(
          \ a:cur_text, a:col, cur_word)
  else
    call s:snippets_jump(a:cur_text, a:col)
  endif
endfunction"}}}
function! s:snippets_jump_or_expand(cur_text, col)"{{{
  let cur_word = s:get_cursor_snippet(
        \ neosnippet#get_snippets(), a:cur_text)
  if search(s:get_placeholder_marker_pattern(). '\|'
            \ .s:get_sync_placeholder_marker_pattern(), 'nw') > 0
    " Found snippet placeholder.
    call s:snippets_jump(a:cur_text, a:col)
  else
    call neosnippet#expand(
          \ a:cur_text, a:col, cur_word)
  endif
endfunction"}}}

function! neosnippet#expand(cur_text, col, trigger_name)"{{{
  if a:trigger_name == ''
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

  let snippets = neosnippet#get_snippets()
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
        \ s:get_placeholder_marker_substitute_pattern(),
        \ '<`\1`>', 'g')
  let snip_word = substitute(snip_word,
        \ s:get_mirror_placeholder_marker_substitute_pattern(),
        \ '<|\1|>', 'g')

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

  call setline('.', snippet_lines[0])
  if len(snippet_lines) > 1
    call append('.', snippet_lines[1:])
  endif

  call s:indent_snippet(begin_line, end_line)

  let begin_patterns = (begin_line > 1) ?
        \ [getline(begin_line - 1)] : []
  let end_patterns =  (end_line < line('$')) ?
        \ [getline(end_line + 1)] : []
  call add(s:snippets_expand_stack, {
        \ 'begin_line' : begin_line,
        \ 'begin_patterns' : begin_patterns,
        \ 'end_line' : end_line,
        \ 'end_patterns' : end_patterns,
        \ 'holder_cnt' : 1,
        \ })

  if has('folding') && foldclosed(line('.'))
    " Open fold.
    silent! normal! zO
  endif
  if next_col < col('$')
    startinsert
  else
    startinsert!
  endif

  if snip_word =~ s:get_placeholder_marker_pattern()
    call s:snippets_jump(a:cur_text, a:col)
  endif

  let &l:iminsert = 0
  let &l:imsearch = 0
endfunction"}}}
function! s:indent_snippet(begin, end)"{{{
  let equalprg = &l:equalprg
  let pos = getpos('.')

  try
    setlocal equalprg=

    " Check use of indent plugin.
    if getline(a:begin+1) !~ '^\t\+'
      " Indent begin line.
      call cursor(a:begin, 0)
      silent normal! ==
    endif

    let base_indent = matchstr(getline(a:begin), '^\s\+')
    for line_nr in range(a:begin+1, a:end)
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

function! s:get_snippet_range(begin_line, begin_patterns, end_line, end_patterns)"{{{
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
function! s:search_snippet_range(start, end, cnt)"{{{
  call s:substitute_placeholder_marker(a:start, a:end, a:cnt)

  let pattern = substitute(
        \ s:get_placeholder_marker_pattern(), '\\d\\+', a:cnt, '')

  let line = a:start
  for line in filter(range(a:start, a:end),
        \ 'getline(v:val) =~ pattern')
    call s:expand_placeholder(a:start, a:end, a:cnt, line)
    return 1
  endfor

  return 0
endfunction"}}}
function! s:search_outof_range(col)"{{{
  call s:substitute_placeholder_marker(1, 0, 0)

  let pattern = s:get_placeholder_marker_pattern()
  if search(pattern, 'w') > 0
    call s:expand_placeholder(line('.'), 0, '\\d\\+', line('.'))
    return 1
  endif

  let pos = getpos('.')
  if a:col == 1
    let pos[2] = 1
    call setpos('.', pos)
    startinsert
  elseif a:col == col('$')
    startinsert!
  else
    let pos[2] = a:col+1
    call setpos('.', pos)
    startinsert
  endif

  " Not found.
  return 0
endfunction"}}}
function! s:expand_placeholder(start, end, holder_cnt, line)"{{{
  let pattern = substitute(s:get_placeholder_marker_pattern(),
        \ '\\d\\+', a:holder_cnt, '')
  let current_line = getline(a:line)
  let match = match(current_line, pattern)

  let default_pattern = substitute(
        \ s:get_placeholder_marker_default_pattern(),
        \ '\\d\\+', a:holder_cnt, '')
  let default = substitute(
        \ matchstr(current_line, default_pattern), '\\\ze[^\\]', '', 'g')
  " Substitute marker.
  let default = substitute(default,
        \ s:get_placeholder_marker_substitute_pattern(),
        \ '<`\1`>', 'g')
  let default = substitute(default,
        \ s:get_mirror_placeholder_marker_substitute_pattern(),
        \ '<|\1|>', 'g')

  let default_len = len(default)

  let pos = getpos('.')
  let pos[1] = a:line
  let pos[2] = match+1

  let cnt = s:search_sync_placeholder(a:start, a:end, a:holder_cnt)
  if cnt > 0
    let pattern = substitute(s:get_placeholder_marker_pattern(),
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

  if default_len > 0
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
function! s:search_sync_placeholder(start, end, number)"{{{
  if a:end == 0
    " Search in current buffer.
    let cnt = matchstr(getline('.'),
          \ substitute(s:get_placeholder_marker_pattern(),
          \ '\\d\\+', '\\zs\\d\\+\\ze', ''))
    return search(substitute(
          \ s:get_mirror_placeholder_marker_pattern(),
          \ '\\d\\+', cnt, ''), 'nw') > 0 ? cnt : 0
  endif

  let pattern = substitute(
          \ s:get_mirror_placeholder_marker_pattern(),
          \ '\\d\\+', a:number, '')
  for line in filter(range(a:start, a:end),
        \ 'getline(v:val) =~ pattern')
    return a:number
  endfor

  return 0
endfunction"}}}
function! s:substitute_placeholder_marker(start, end, snippet_holder_cnt)"{{{
  if a:snippet_holder_cnt > 1
    let cnt = a:snippet_holder_cnt-1
    let sync_marker = substitute(s:get_sync_placeholder_marker_pattern(),
        \ '\\d\\+', cnt, '')
    let mirror_marker = substitute(
          \ s:get_mirror_placeholder_marker_pattern(),
          \ '\\d\\+', cnt, '')
    let line = a:start

    for line in range(a:start, a:end)
      if getline(line) =~ sync_marker
        let sub = escape(matchstr(getline(line),
              \ substitute(s:get_sync_placeholder_marker_default_pattern(),
              \ '\\d\\+', cnt, '')), '/\')
        silent execute printf('%d,%ds/' . mirror_marker . '/%s/'
          \ . (&gdefault ? '' : 'g'), a:start, a:end, sub)
        call setline(line, substitute(getline(line), sync_marker, sub, ''))
      endif
    endfor
  elseif search(s:get_sync_placeholder_marker_pattern(), 'wb') > 0
    let sub = escape(matchstr(getline('.'),
          \ s:get_sync_placeholder_marker_default_pattern()), '/\')
    let cnt = matchstr(getline('.'),
          \ substitute(s:get_sync_placeholder_marker_pattern(),
          \ '\\d\\+', '\\zs\\d\\+\\ze', ''))
    silent execute printf('%%s/' . mirror_marker . '/%s/'
          \ . (&gdefault ? 'g' : ''), sub)
    let sync_marker = substitute(s:get_sync_placeholder_marker_pattern(),
        \ '\\d\\+', cnt, '')
    let mirror_marker = substitute(
          \ s:get_mirror_placeholder_marker_pattern(),
          \ '\\d\\+', cnt, '')
    call setline('.', substitute(getline('.'), sync_marker, sub, ''))
  endif
endfunction"}}}
function! s:eval_snippet(snippet_text)"{{{
  let snip_word = ''
  let prev_match = 0
  let match = match(a:snippet_text, '\\\@<!`.\{-}\\\@<!`')

  while match >= 0
    if match - prev_match > 0
      let snip_word .= a:snippet_text[prev_match : match - 1]
    endif
    let prev_match = matchend(a:snippet_text,
          \ '\\\@<!`.\{-}\\\@<!`', match)
    sandbox let snip_word .= eval(
          \ a:snippet_text[match+1 : prev_match - 2])

    let match = match(a:snippet_text, '\\\@<!`.\{-}\\\@<!`', prev_match)
  endwhile
  if prev_match >= 0
    let snip_word .= a:snippet_text[prev_match :]
  endif

  return snip_word
endfunction"}}}
function! neosnippet#get_snippets()"{{{
  let snippets = {}
  for filetype in s:get_sources_filetypes(neosnippet#get_filetype())
    call neosnippet#make_cache(filetype)
    call extend(snippets, s:snippets[filetype], 'keep')
  endfor

  if !s:is_beginning_of_line(neosnippet#util#get_cur_text())
    call filter(snippets, '!v:val.is_head')
  endif

  return snippets
endfunction"}}}
function! neosnippet#get_snippets_directory()"{{{
  let snippets_dir = copy(s:snippets_dir)
  if !get(g:neosnippet#disable_runtime_snippets,
        \ neosnippet#get_filetype(),
        \ get(g:neosnippet#disable_runtime_snippets, '_', 0))
    let snippets_dir += s:runtime_dir
  endif

  return snippets_dir
endfunction"}}}
function! neosnippet#get_filetype()"{{{
  return exists('*neocomplcache#get_context_filetype') ?
        \ neocomplcache#get_context_filetype(1) : &filetype
endfunction"}}}
function! s:get_sources_filetypes(filetype)"{{{
  return (exists('*neocomplcache#get_source_filetypes') ?
        \ neocomplcache#get_source_filetypes(a:filetype) :
        \ [a:filetype]) + ['_']
endfunction"}}}

function! neosnippet#edit_complete(arglead, cmdline, cursorpos)"{{{
  return filter(s:neosnippet_options + neosnippet#filetype_complete(
        \ a:arglead, a:cmdline, a:cursorpos), 'stridx(v:val, a:arglead) == 0')
endfunction"}}}
" Complete filetype helper.
function! neosnippet#filetype_complete(arglead, cmdline, cursorpos)"{{{
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

function! s:get_placeholder_marker_pattern()"{{{
  return '<`\d\+\%(:.\{-}\)\?\\\@<!`>'
endfunction"}}}
function! s:get_placeholder_marker_substitute_pattern()"{{{
  return '\${\(\d\+\%(:.\{-}\)\?\\\@<!\)}'
endfunction"}}}
function! s:get_placeholder_marker_default_pattern()"{{{
  return '<`\d\+:\zs.\{-}\ze\\\@<!`>'
endfunction"}}}
function! s:get_sync_placeholder_marker_pattern()"{{{
  return '<{\d\+\%(:.\{-}\)\?\\\@<!}>'
endfunction"}}}
function! s:get_sync_placeholder_marker_default_pattern()"{{{
  return '<{\d\+:\zs.\{-}\ze\\\@<!}>'
endfunction"}}}
function! s:get_mirror_placeholder_marker_pattern()"{{{
  return '<|\d\+|>'
endfunction"}}}
function! s:get_mirror_placeholder_marker_substitute_pattern()"{{{
  return '\$\(\d\+\)'
endfunction"}}}

function! s:SID_PREFIX()"{{{
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction"}}}

function! s:trigger(function)"{{{
  let cur_text = neosnippet#util#get_cur_text()

  let col = col('.')
  if mode() !=# 'i'
    " Fix column.
    let col += 2
  endif

  return printf("\<ESC>:call %s(%s,%d)\<CR>",
        \ a:function, string(cur_text), col)
endfunction"}}}

" Plugin key-mappings.
function! neosnippet#expand_or_jump_impl()
  return s:trigger(s:SID_PREFIX().'snippets_expand_or_jump')
endfunction
function! neosnippet#jump_or_expand_impl()
  return s:trigger(s:SID_PREFIX().'snippets_jump_or_expand')
endfunction
function! neosnippet#expand_impl()
  return s:trigger(s:SID_PREFIX().'snippets_expand')
endfunction
function! neosnippet#jump_impl()
  return s:trigger(s:SID_PREFIX().'snippets_jump')
endfunction

if !exists('s:snippets')
  let s:snippets = {}

  call s:initialize()
endif

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
