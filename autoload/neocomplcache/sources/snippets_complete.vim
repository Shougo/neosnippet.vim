"=============================================================================
" FILE: snippets_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 05 Apr 2012.
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

if !exists('s:snippets')
  let s:snippets = {}
endif

let s:source = {
      \ 'name' : 'snippets_complete',
      \ 'kind' : 'plugin',
      \}

function! s:source.initialize()"{{{
  " Initialize.
  let s:snippets = {}
  let s:snippets_expand_stack = []

  if !exists('g:neocomplcache_snippets_disable_runtime_snippets')
    let g:neocomplcache_snippets_disable_runtime_snippets = 0
  endif

  call neocomplcache#set_dictionary_helper(
        \ g:neocomplcache_source_rank, 'snippets_complete', 8)

  let s:snippets_dir = []
  let s:runtime_dir = split(globpath(&runtimepath,
        \ 'autoload/neocomplcache/sources/snippets_complete'), '\n')

  if !g:neocomplcache_snippets_disable_runtime_snippets
    " Set snippets dir.
    let s:snippets_dir += (exists('g:snippets_dir') ?
          \ split(g:snippets_dir, '\s*,\s*')
          \ : split(globpath(&runtimepath, 'snippets'), '\n'))
          \ + s:runtime_dir
  endif

  if exists('g:neocomplcache_snippets_dir')
    for dir in split(g:neocomplcache_snippets_dir, '\s*,\s*')
      let dir = neocomplcache#util#expand(dir)
      if !isdirectory(dir)
        call mkdir(dir, 'p')
      endif
      call add(s:snippets_dir, dir)
    endfor
  endif
  call map(s:snippets_dir, 'substitute(v:val, "[\\\\/]$", "", "")')

  augroup neocomplcache"{{{
    " Set caching event.
    autocmd FileType * call s:caching()
    " Recaching events
    autocmd BufWritePost *.snip,*.snippets call s:caching_snippets(expand('<afile>:t:r'))
    " Detect syntax file.
    autocmd BufNewFile,BufRead *.snip,*.snippets set filetype=snippet
  augroup END"}}}

  if has('conceal')
    " Supported conceal features.
    augroup neocomplcache
      autocmd BufNewFile,BufRead,ColorScheme *
            \ syn match   neocomplcacheExpandSnippets
            \ '<`\d\+:\|`>\|<{\d\+:\|}>' conceal
      autocmd BufNewFile,BufRead,ColorScheme *
            \ execute 'syn match   neocomplcacheExpandSnippets'
            \  '''<`\d\+\\\@<!`>\|<{\d\+\\\@<!}>\|'
            \ .s:get_mirror_placeholder_marker_pattern()."'"
            \ 'conceal cchar=$'
    augroup END
  else
    augroup neocomplcache
      autocmd BufNewFile,BufRead,ColorScheme *
            \ execute 'syn match   neocomplcacheExpandSnippets'
            \  "'".s:get_placeholder_marker_pattern(). '\|'
            \ .s:get_sync_placeholder_marker_pattern().'\|'
            \ .s:get_mirror_placeholder_marker_pattern()."'"
    augroup END
  endif

  hi def link NeoComplCacheExpandSnippets Special

  command! -nargs=? -complete=customlist,neocomplcache#filetype_complete
        \ NeoComplCacheEditSnippets
        \ call s:edit_snippets(<q-args>, 0)
  command! -nargs=? -complete=customlist,neocomplcache#filetype_complete
        \ NeoComplCacheEditRuntimeSnippets
        \ call s:edit_snippets(<q-args>, 1)
  command! -nargs=? -complete=customlist,neocomplcache#filetype_complete
        \ NeoComplCacheCachingSnippets
        \ call s:caching_snippets(<q-args>)

  " Select mode mappings.
  if !exists('g:neocomplcache_disable_select_mode_mappings')
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
  endif

  " Caching _ snippets.
  call s:caching_snippets('_')

  " Initialize check.
  call s:caching()

  if neocomplcache#exists_echodoc()
    call echodoc#register('snippets_complete', s:doc_dict)
  endif
endfunction"}}}

function! s:source.finalize()"{{{
  delcommand NeoComplCacheEditSnippets
  delcommand NeoComplCacheEditRuntimeSnippets
  delcommand NeoComplCacheCachingSnippets

  hi clear NeoComplCacheExpandSnippets

  if neocomplcache#exists_echodoc()
    call echodoc#unregister('snippets_complete')
  endif
endfunction"}}}

function! s:source.get_keyword_list(cur_keyword_str)"{{{
  if !has_key(s:snippets, '_')
    " Caching _ snippets.
    call s:caching_snippets('_')
  endif
  let snippets = values(s:snippets['_'])

  let filetype = neocomplcache#get_context_filetype()
  if !has_key(s:snippets, filetype)
    " Caching snippets.
    call s:caching_snippets(filetype)
  endif
  for source in neocomplcache#get_sources_list(s:snippets, filetype)
    let snippets += values(source)
  endfor

  return s:keyword_filter(neocomplcache#dup_filter(snippets),
        \ a:cur_keyword_str)
endfunction"}}}

function! neocomplcache#sources#snippets_complete#define()"{{{
  return s:source
endfunction"}}}

function! s:compare_words(i1, i2)
  return a:i1.menu - a:i2.menu
endfunction

" For echodoc."{{{
let s:doc_dict = {
      \ 'name' : 'snippets_complete',
      \ 'rank' : 100,
      \ 'filetypes' : {},
      \ }
function! s:doc_dict.search(cur_text)"{{{
  if mode() !=# 'i'
    return []
  endif

  let snippets = neocomplcache#sources#snippets_complete#get_snippets()

  let cur_word = s:get_cursor_keyword_snippet(snippets, a:cur_text)
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

function! s:keyword_filter(list, cur_keyword_str)"{{{
  let keyword_escape = neocomplcache#keyword_escape(a:cur_keyword_str)

  let prev_word = neocomplcache#get_prev_word(a:cur_keyword_str)
  " Keyword filter.
  let pattern = printf('v:val.word =~ %s && (!has_key(v:val, "prev_word") || v:val.prev_word == %s)',
        \string('^' . keyword_escape), string(prev_word))

  let list = filter(a:list, pattern)

  " Substitute abbr.
  let abbr_pattern = printf('%%.%ds..%%s',
        \ g:neocomplcache_max_keyword_width-10)
  for snippet in list
    if snippet.snip =~ '\\\@<!`=.*\\\@<!`'
      let snippet.menu = s:eval_snippet(snippet.snip)

      if g:neocomplcache_max_keyword_width >= 0 &&
            \ len(snippet.menu) > g:neocomplcache_max_keyword_width
        let snippet.menu = printf(abbr_pattern,
              \ snippet.menu, snippet.menu[-8:])
      endif
      let snippet.menu = '`Snip` ' . snippet.menu
    endif
  endfor

  return list
endfunction"}}}

function! neocomplcache#sources#snippets_complete#expandable()"{{{
  let ret = 0

  if neocomplcache#sources#snippets_complete#force_expandable()
    let ret += 1
  endif

  if neocomplcache#sources#snippets_complete#jumpable()
    let ret += 2
  endif

  return ret
endfunction"}}}
function! neocomplcache#sources#snippets_complete#force_expandable()"{{{
  let snippets = neocomplcache#sources#snippets_complete#get_snippets()
  let cur_text = neocomplcache#get_cur_text(1)

  " Found snippet trigger.
  return s:get_cursor_keyword_snippet(snippets, cur_text) != ''
endfunction"}}}
function! neocomplcache#sources#snippets_complete#jumpable()"{{{
  " Found snippet placeholder.
  return search(s:get_placeholder_marker_pattern(). '\|'
            \ .s:get_sync_placeholder_marker_pattern(), 'nw') > 0
endfunction"}}}

function! s:caching()"{{{
  for filetype in neocomplcache#get_source_filetypes(
        \ neocomplcache#get_context_filetype(1))
    if !has_key(s:snippets, filetype)
      call s:caching_snippets(filetype)
    endif
  endfor
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

    let abbr = (g:neocomplcache_max_keyword_width >= 0 &&
          \       len(alias) > g:neocomplcache_max_keyword_width) ?
          \ printf(abbr_pattern, alias, alias[-8:]) : alias
    let alias_pattern.abbr = abbr
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
  let abbr_pattern = printf('%%.%ds..%%s',
        \ g:neocomplcache_max_keyword_width-10)

  let a:dict.word = substitute(a:dict.word, '\n$', '', '')
  let menu_pattern =
        \ (a:dict.word =~ '\${\d\+\%(:.\{-}\)\?\\\@<!}') ?
        \ '<Snip> ' : '[Snip] '

  let abbr = get(a:dict, 'abbr', substitute(a:dict.word,
        \   s:get_placeholder_marker_pattern(). '\|'.
        \   s:get_mirror_placeholder_marker_pattern().
        \   '\|\s\+\|\n', ' ', 'g'))
  let abbr = (g:neocomplcache_max_keyword_width >= 0 &&
        \ len(abbr) > g:neocomplcache_max_keyword_width)?
        \ printf(abbr_pattern, abbr, abbr[-8:]) : abbr

  let dict = {
        \ 'word' : a:dict.name,
        \ 'snip' : a:dict.word, 'abbr' : a:dict.name,
        \ 'description' : a:dict.word,
        \ 'menu' : menu_pattern . abbr, 'dup' : 1
        \}
  if has_key(a:dict, 'prev_word')
    let dict.prev_word = a:dict.prev_word
  endif
  return dict
endfunction"}}}

function! s:edit_snippets(filetype, isruntime)"{{{
  if a:filetype == ''
    let filetype = neocomplcache#get_context_filetype(1)
  else
    let filetype = a:filetype
  endif

  " Edit snippet file.
  if a:isruntime
    if empty(s:runtime_dir)
      return
    endif

    let filename = s:runtime_dir[0].'/'.filetype.'.snip'
  else
    if empty(s:snippets_dir)
      return
    endif

    let filename = s:snippets_dir[-1].'/'.filetype.'.snip'
  endif

  if filereadable(filename)
    edit `=filename`
  else
    enew
    setfiletype snippet
    saveas `=filename`
  endif
endfunction"}}}

function! s:caching_snippets(filetype)"{{{
  let filetype = a:filetype == '' ?
        \ &filetype : a:filetype

  let snippet = {}
  let snippets_files = split(globpath(join(s:snippets_dir, ','),
        \ filetype .  '.snip*'), '\n')
        \ + split(globpath(join(s:snippets_dir, ','),
        \ filetype .  '_*.snip*'), '\n')
  for snippets_file in snippets_files
    call s:load_snippets(snippet, snippets_file)
  endfor

  let s:snippets[filetype] = snippet
endfunction"}}}

function! s:load_snippets(snippet, snippets_file)"{{{
  let dup_check = {}
  let snippet_pattern = { 'word' : '' }
  let abbr_pattern = printf('%%.%ds..%%s',
        \ g:neocomplcache_max_keyword_width-10)

  let linenr = 1

  for line in readfile(a:snippets_file)
    if line =~ '^\h\w*.*\s$'
      " Delete spaces.
      let line = substitute(line, '\s\+$', '', '')
    endif

    if line =~ '^include'
      " Include snippets.
      let snippet_file = matchstr(line, '^include\s\+\zs.*$')
      for snippets_file in split(globpath(join(s:snippets_dir, ','),
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
        call neocomplcache#print_error(
              \ 'Warning: ' . a:snippets_file . ':'
              \ . linenr . ': duplicated snippet name `'
              \ . snippet_pattern.name . '`')
        call neocomplcache#print_error(
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
        let snippet_pattern.prev_word = matchstr(line,
              \ '^prev_word\s\+[''"]\zs.*\ze[''"]$')
      elseif line =~ '^\s'
        if snippet_pattern.word == ''
          let snippet_pattern.word = matchstr(line, '^\s\+\zs.*$')
        else
          let snippet_pattern.word .= "\n"
                \ . matchstr(line, '^\%(\t\| *\)\zs.*$')
        endif
      elseif line =~ '^$'
        " Blank line.
        let snippet_pattern.word .= "\n"
      endif
    endif

    let linenr += 1
  endfor

  " Set previous snippet.
  call s:set_snippet_dict(snippet_pattern,
        \ a:snippet, dup_check, a:snippets_file)

  return a:snippet
endfunction"}}}

function! s:get_cursor_keyword_snippet(snippets, cur_text)"{{{
  let cur_word = matchstr(a:cur_text,
        \ neocomplcache#get_keyword_pattern_end().'\|\h\w*\W\+$')

  " Check prev_word.
  let prev_word = neocomplcache#get_prev_word(cur_word)
  let pattern = printf('(!has_key(v:val, "prev_word") || v:val.prev_word ==# %s)',
        \ string(prev_word))

  let dict = filter(copy(a:snippets), pattern)
  if !has_key(dict, cur_word)
    let cur_word = ''
  endif

  return cur_word
endfunction"}}}
function! s:get_cursor_snippet(snippets, cur_text)"{{{
  let cur_word = matchstr(a:cur_text, '\S\+$')
  while cur_word != '' && !has_key(a:snippets, cur_word)
    let cur_word = cur_word[1:]
  endwhile

  return cur_word
endfunction"}}}
function! s:snippets_force_expand(cur_text, col)"{{{
  let cur_word = s:get_cursor_snippet(
        \ neocomplcache#sources#snippets_complete#get_snippets(),
        \ a:cur_text)

  call neocomplcache#sources#snippets_complete#expand(
        \ a:cur_text, a:col, cur_word)
endfunction"}}}
function! s:snippets_expand_or_jump(cur_text, col)"{{{
  let cur_word = s:get_cursor_keyword_snippet(
        \ neocomplcache#sources#snippets_complete#get_snippets(),
        \ a:cur_text)
  if cur_word != ''
    " Found snippet trigger.
    call neocomplcache#sources#snippets_complete#expand(
          \ a:cur_text, a:col, cur_word)
  else
    call s:snippets_force_jump(a:cur_text, a:col)
  endif
endfunction"}}}
function! s:snippets_jump_or_expand(cur_text, col)"{{{
  let cur_word = s:get_cursor_keyword_snippet(
        \ neocomplcache#sources#snippets_complete#get_snippets(), a:cur_text)
  if search(s:get_placeholder_marker_pattern(). '\|'
            \ .s:get_sync_placeholder_marker_pattern(), 'nw') > 0
    " Found snippet placeholder.
    call s:snippets_force_jump(a:cur_text, a:col)
  else
    call neocomplcache#sources#snippets_complete#expand(
          \ a:cur_text, a:col, cur_word)
  endif
endfunction"}}}

function! neocomplcache#sources#snippets_complete#expand(cur_text, col, trigger_name)"{{{
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

  let snippets = neocomplcache#sources#snippets_complete#get_snippets()
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

  call setline(line('.'), snippet_lines[0])
  if len(snippet_lines) > 1
    call append(line('.'), snippet_lines[1:])
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
    call s:snippets_force_jump(a:cur_text, a:col)
  endif

  let &l:iminsert = 0
  let &l:imsearch = 0
endfunction"}}}
function! s:indent_snippet(begin, end)"{{{
  let equalprg = &l:equalprg
  setlocal equalprg=

  let pos = getpos('.')

  let base_indent = matchstr(getline(a:begin), '^\s\+')
  for line_nr in range(a:begin, a:end)
    call cursor(line_nr, 0)

    if getline('.') =~ '^\t\+'
      if &l:expandtab
        " Expand tab.
        cal setline('.', substitute(getline('.'),
              \ '^\t\+', base_indent . repeat(' ', &shiftwidth *
              \    len(matchstr(getline('.'), '^\t\+'))), ''))
      elseif line_nr != a:begin
        call setline('.', base_indent . getline('.'))
      endif
    else
      silent normal! ==
    endif
  endfor

  call setpos('.', pos)

  let &l:equalprg = equalprg
endfunction"}}}

function! s:snippets_force_jump(cur_text, col)"{{{
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
function! s:get_snippet_range(begin_line, begin_patterns, end_line, end_patterns)"{{{
  let pos = getpos('.')

  call cursor(a:begin_line, 0)
  if empty(a:begin_patterns)
    let begin = line('.') - 50
  else
    let [begin, _] = searchpos('^' . neocomplcache#util#escape_pattern(
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
    let [end, _] = searchpos('^' . neocomplcache#util#escape_pattern(
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
    call s:expand_placeholder(line('.'), 0, '\d\+', line('.'))
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
        \ matchstr(current_line, default_pattern), '\\\ze.', '', 'g')
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
function! s:trigger(function)"{{{
  let cur_text = neocomplcache#get_cur_text(1)
  return printf("\<ESC>:call %s(%s,%d)\<CR>",
        \ a:function, string(cur_text), col('.'))
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
    let snip_word .= eval(a:snippet_text[match+1 : prev_match - 2])

    let match = match(a:snippet_text, '\\\@<!`.\{-}\\\@<!`', prev_match)
  endwhile
  if prev_match >= 0
    let snip_word .= a:snippet_text[prev_match :]
  endif

  return snip_word
endfunction"}}}
function! neocomplcache#sources#snippets_complete#get_snippets()"{{{
  " Get buffer filetype.
  let filetype = neocomplcache#get_context_filetype(1)

  let snippets = {}
  for source in neocomplcache#get_sources_list(s:snippets, filetype)
      call extend(snippets, source, 'keep')
  endfor
  call extend(snippets, copy(s:snippets['_']), 'keep')

  return snippets
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

" Plugin key-mappings.
inoremap <silent><expr> <Plug>(neocomplcache_snippets_expand)
      \ <SID>trigger(<SID>SID_PREFIX().'snippets_expand_or_jump')
snoremap <silent><expr> <Plug>(neocomplcache_snippets_expand)
      \ <SID>trigger(<SID>SID_PREFIX().'snippets_expand_or_jump')
inoremap <silent><expr> <Plug>(neocomplcache_snippets_jump)
      \ <SID>trigger(<SID>SID_PREFIX().'snippets_jump_or_expand')
snoremap <silent><expr> <Plug>(neocomplcache_snippets_jump)
      \ <SID>trigger(<SID>SID_PREFIX().'snippets_jump_or_expand')
inoremap <silent><expr> <Plug>(neocomplcache_snippets_force_expand)
      \ <SID>trigger(<SID>SID_PREFIX().'snippets_force_expand')
snoremap <silent><expr> <Plug>(neocomplcache_snippets_force_expand)
      \ <SID>trigger(<SID>SID_PREFIX().'snippets_force_expand')
inoremap <silent><expr> <Plug>(neocomplcache_snippets_force_jump)
      \ <SID>trigger(<SID>SID_PREFIX().'snippets_force_jump')
snoremap <silent><expr> <Plug>(neocomplcache_snippets_force_jump)
      \ <SID>trigger(<SID>SID_PREFIX().'snippets_force_jump')

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
