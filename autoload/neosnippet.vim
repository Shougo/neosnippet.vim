"=============================================================================
" FILE: neosnippet.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 17 Feb 2013.
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
      \ 'g:neosnippet#snippets_directory',
      \ '', 'g:neocomplcache_snippets_dir')
call neosnippet#util#set_default(
      \ 'g:neosnippet#disable_select_mode_mappings',
      \ 1, 'g:neocomplcache_disable_select_mode_mappings')
call neosnippet#util#set_default(
      \ 'g:neosnippet#enable_snipmate_compatibility', 0)
"}}}

" Variables  "{{{
let s:neosnippet_options = [
      \ '-runtime',
      \ '-vertical', '-horizontal', '-direction=', '-split',
      \]
"}}}

function! neosnippet#_lazy_initialize() "{{{
  if !exists('s:lazy_progress')
    let s:lazy_progress = 0
  endif

  if s:lazy_progress == 0
  elseif s:lazy_progress == 1
    call s:initialize_script_variables()
  elseif s:lazy_progress == 2
    call s:initialize_others()
  else
    call s:initialize_cache()
  endif

  let s:lazy_progress += 1
endfunction"}}}

function! s:check_initialize() "{{{
  if !exists('s:is_initialized')
    let s:is_initialized = 1

    call s:initialize_script_variables()
    call s:initialize_others()
    call s:initialize_cache()
  endif
endfunction"}}}

" For echodoc. "{{{
let s:doc_dict = {
      \ 'name' : 'neosnippet',
      \ 'rank' : 100,
      \ 'filetypes' : {},
      \ }
function! s:doc_dict.search(cur_text) "{{{
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

function! neosnippet#expandable_or_jumpable() "{{{
  return neosnippet#expandable() || neosnippet#jumpable()
endfunction"}}}
function! neosnippet#expandable() "{{{
  " Check snippet trigger.
  return s:get_cursor_snippet(
        \ neosnippet#get_snippets(), neosnippet#util#get_cur_text()) != ''
endfunction"}}}
function! neosnippet#jumpable() "{{{
  " Found snippet placeholder.
  return search(s:get_placeholder_marker_pattern(). '\|'
            \ .s:get_sync_placeholder_marker_pattern(), 'nw') > 0
endfunction"}}}

function! neosnippet#caching() "{{{
  call neosnippet#make_cache(&filetype)
endfunction"}}}

function! neosnippet#recaching() "{{{
  let s:snippets = {}
endfunction"}}}

function! s:set_snippet_dict(snippet_dict, snippets, dup_check, snippets_file) "{{{
  if empty(a:snippet_dict)
    return
  endif

  let action_pattern = '^snippet\s\+' . a:snippet_dict.name . '$'
  let snippet = s:initialize_snippet(
        \ a:snippet_dict, a:snippets_file,
        \ a:snippet_dict.linenr, action_pattern,
        \ a:snippet_dict.name)
  let a:snippets[a:snippet_dict.name] = snippet
  let a:dup_check[a:snippet_dict.name] = snippet

  for alias in get(a:snippet_dict, 'alias', [])
    let alias_snippet = copy(snippet)
    let alias_snippet.word = alias
    let alias_snippet.filter_str = alias

    let a:snippets[alias] = alias_snippet
    let a:dup_check[alias] = alias_snippet
  endfor
endfunction"}}}
function! s:initialize_snippet(dict, path, line, pattern, name) "{{{
  let a:dict.word = substitute(a:dict.word, '\n\+$', '', '')
  if a:dict.word !~
        \ s:get_placeholder_marker_substitute_pattern()
    " Add placeholder.
    let a:dict.word .= '${0}'
  endif

  if a:dict.word =~ '\\\@<!`.*\\\@<!`'
    let menu_prefix = '`Snip` '
  elseif a:dict.word =~
        \ s:get_placeholder_marker_substitute_pattern()
        \ . '.*' . s:get_placeholder_marker_substitute_pattern()
    let menu_prefix = '<Snip> '
  else
    let menu_prefix = '[Snip] '
  endif

  if !has_key(a:dict, 'abbr') || a:dict.abbr == ''
    " Set default abbr.
    let abbr = substitute(a:dict.word,
        \   s:get_placeholder_marker_pattern(). '\|'.
        \   s:get_mirror_placeholder_marker_pattern().
        \   '\|\s\+\|\n', ' ', 'g')
    let a:dict.abbr = a:dict.name
  else
    let abbr = a:dict.abbr
  endif

  let snippet = {
        \ 'word' : a:dict.name, 'snip' : a:dict.word,
        \ 'filter_str' : a:dict.name . ' ' . a:dict.abbr,
        \ 'description' : a:dict.word,
        \ 'menu' : menu_prefix . abbr,
        \ 'options' : a:dict.options,
        \ 'action__path' : a:path, 'action__line' : a:line,
        \ 'action__pattern' : a:pattern, 'real_name' : a:name,
        \}

  if has_key(a:dict, 'regexp')
    let snippet.regexp = a:dict.regexp
  endif

  return snippet
endfunction"}}}
function! s:initialize_snippet_options() "{{{
  return { 'head' : 0, 'word' : 0, 'indent' : 0 }
endfunction"}}}

function! neosnippet#edit_snippets(args) "{{{
  call s:check_initialize()

  let [args, options] = neosnippet#util#parse_options(
        \ a:args, s:neosnippet_options)

  let filetype = get(args, 0, '')
  if filetype == ''
    let filetype = neosnippet#get_filetype()
  endif

  let options = s:initialize_options(options)
  let snippet_dir = (options.runtime ?
        \ get(neosnippet#get_runtime_snippets_directory(), 0, '') :
        \ get(neosnippet#get_user_snippets_directory(), -1, ''))

  if snippet_dir == ''
    call neosnippet#util#print_error('Snippet directory is not found.')
    return
  endif

  " Edit snippet file.
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
          \ (options.vertical ? 'vsplit' : 'split')
  endif

  try
    edit `=filename`
  catch /^Vim\%((\a\+)\)\=:E749/
  endtry
endfunction"}}}

function! s:initialize_options(options) "{{{
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

function! neosnippet#make_cache(filetype) "{{{
  call s:check_initialize()

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
    call s:parse_snippets_file(snippet, snippets_file)
  endfor

  let s:snippets[filetype] = snippet
endfunction"}}}

function! neosnippet#source_file(filename) "{{{
  call s:check_initialize()

  let neosnippet = neosnippet#get_current_neosnippet()
  call s:parse_snippets_file(neosnippet.snippets, a:filename)
endfunction"}}}

function! s:parse_snippets_file(snippets, snippets_file) "{{{
  let dup_check = {}
  let snippet_dict = {}

  let linenr = 1

  if !filereadable(a:snippets_file)
    call neosnippet#util#print_error(
          \ printf('snippet file "%s" is not found.', a:snippets_file))
    return a:snippets
  endif

  for line in readfile(a:snippets_file)
    if line =~ '^\h\w*.*\s$'
      " Delete spaces.
      let line = substitute(line, '\s\+$', '', '')
    endif

    if line =~ '^#'
      " Ignore.
    elseif line =~ '^include'
      " Include snippets.
      let filename = matchstr(line, '^include\s\+\zs.*$')

      for snippets_file in split(globpath(join(
            \ neosnippet#get_snippets_directory(), ','),
            \ filename), '\n')
        call s:parse_snippets_file(a:snippets, snippets_file)
      endfor
    elseif line =~ '^delete\s'
      let name = matchstr(line, '^delete\s\+\zs.*$')
      if name != '' && has_key(a:snippets, name)
        call filter(a:snippets, 'v:val.real_name !=# name')
      endif
    elseif line =~ '^snippet\s'
      if !empty(snippet_dict)
        " Set previous snippet.
        call s:set_snippet_dict(snippet_dict,
              \ a:snippets, dup_check, a:snippets_file)
      endif

      let snippet_dict = s:parse_snippet_name(
            \ a:snippets_file, line, linenr, dup_check)
    elseif !empty(snippet_dict)
      if line =~ '^\s' || line == ''
        if snippet_dict.word == ''
          " Substitute head tab character.
          let line = substitute(line, '^\t', '', '')
        endif

        let snippet_dict.word .=
                \ substitute(line, '^ *', '', '') . "\n"
      else
        call s:add_snippet_attribute(
              \ a:snippets_file, line, linenr, snippet_dict)
      endif
    endif

    let linenr += 1
  endfor

  if !empty(snippet_dict)
    " Set previous snippet.
    call s:set_snippet_dict(snippet_dict,
          \ a:snippets, dup_check, a:snippets_file)
  endif

  return a:snippets
endfunction"}}}

function! s:parse_snippet_name(snippets_file, line, linenr, dup_check) "{{{
  " Initialize snippet dict.
  let snippet_dict = { 'word' : '', 'linenr' : a:linenr,
        \ 'options' : s:initialize_snippet_options() }

  " Try using the name without the description (abbr).
  let snippet_dict.name = matchstr(a:line, '^snippet\s\+\zs\S\+')

  " Fall back to using the name and description (abbr) combined.
  " SnipMate snippets may have duplicate names, but different
  " descriptions (abbrs).
  let description = matchstr(a:line, '^snippet\s\+\S\+\s\+\zs.*$')
  if description != '' && description !=# snippet_dict.name
    " Convert description.
    let snippet_dict.name .= '_' .
          \ substitute(substitute(
          \    description, '\W\+', '_', 'g'), '_\+$', '', '')
  endif

  " Collect the description (abbr) of the snippet, if set on snippet line.
  " This is for compatibility with SnipMate-style snippets.
  let snippet_dict.abbr = matchstr(a:line,
        \ '^snippet\s\+\S\+\s\+\zs.*$')

  " Check for duplicated names.
  if has_key(a:dup_check, snippet_dict.name)
    let dup = a:dup_check[snippet_dict.name]
    call neosnippet#util#print_error(printf(
          \ 'Warning: %s:%d is overriding `%s` from %s:%d',
          \ a:snippets_file, a:linenr, snippet_dict.name,
          \ dup.action__path, dup.action__line))
    call neosnippet#util#print_error(printf(
          \ 'Please rename the snippet name or use `delete %s`.',
          \ snippet_dict.name))
  endif

  return snippet_dict
endfunction"}}}
function! s:add_snippet_attribute(snippets_file, line, linenr, snippet_dict) "{{{
  " Allow overriding/setting of the description (abbr) of the snippet.
  " This will override what was set via the snippet line.
  if a:line =~ '^abbr\s'
    let a:snippet_dict.abbr = matchstr(a:line, '^abbr\s\+\zs.*$')
  elseif a:line =~ '^alias\s'
    let a:snippet_dict.alias = split(matchstr(a:line,
          \ '^alias\s\+\zs.*$'), '[,[:space:]]\+')
  elseif a:line =~ '^prev_word\s'
    let prev_word = matchstr(a:line,
          \ '^prev_word\s\+[''"]\zs.*\ze[''"]$')
    if prev_word == '^'
      " For backward compatibility.
      let a:snippet_dict.options.head = 1
    else
      call neosnippet#util#print_error(
            \ 'prev_word must be "^" character.')
    endif
  elseif a:line =~ '^regexp\s'
    let a:snippet_dict.regexp = matchstr(a:line,
          \ '^regexp\s\+[''"]\zs.*\ze[''"]$')
  elseif a:line =~ '^options\s\+'
    for option in split(matchstr(a:line,
          \ '^options\s\+\zs.*$'), '[,[:space:]]\+')
      if !has_key(a:snippet_dict.options, option)
        call neosnippet#util#print_error(
              \ printf('[neosnippet] %s:%d', a:snippets_file, a:linenr))
        call neosnippet#util#print_error(
              \ printf('[neosnippet] Invalid option name : "%s"', option))
      else
        let a:snippet_dict.options[option] = 1
      endif
    endfor
  else
    call neosnippet#util#print_error(
          \ printf('[neosnippet] %s:%d', a:snippets_file, a:linenr))
    call neosnippet#util#print_error(
          \ printf('[neosnippet] Invalid syntax : "%s"', a:line))
  endif
endfunction"}}}

function! s:is_beginning_of_line(cur_text) "{{{
  let keyword_pattern = '\S\+'
  let cur_keyword_str = matchstr(a:cur_text, keyword_pattern.'$')
  let line_part = a:cur_text[: -1-len(cur_keyword_str)]
  let prev_word_end = matchend(line_part, keyword_pattern)

  return prev_word_end <= 0
endfunction"}}}
function! s:get_cursor_snippet(snippets, cur_text) "{{{
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

function! s:snippets_expand(cur_text, col) "{{{
  let cur_word = s:get_cursor_snippet(
        \ neosnippet#get_snippets(),
        \ a:cur_text)

  call neosnippet#expand(
        \ a:cur_text, a:col, cur_word)
endfunction"}}}
function! neosnippet#jump(cur_text, col) "{{{
  call s:skip_next_auto_completion()

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
function! s:snippets_expand_or_jump(cur_text, col) "{{{
  let cur_word = s:get_cursor_snippet(
        \ neosnippet#get_snippets(), a:cur_text)

  if cur_word != ''
    " Found snippet trigger.
    call neosnippet#expand(
          \ a:cur_text, a:col, cur_word)
  else
    call neosnippet#jump(a:cur_text, a:col)
  endif
endfunction"}}}
function! s:snippets_jump_or_expand(cur_text, col) "{{{
  let cur_word = s:get_cursor_snippet(
        \ neosnippet#get_snippets(), a:cur_text)
  if search(s:get_placeholder_marker_pattern(). '\|'
            \ .s:get_sync_placeholder_marker_pattern(), 'nw') > 0
    " Found snippet placeholder.
    call neosnippet#jump(a:cur_text, a:col)
  else
    call neosnippet#expand(
          \ a:cur_text, a:col, cur_word)
  endif
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

  if has('folding')
    let foldmethod = &l:foldmethod
    let &l:foldmethod = 'manual'
  endif

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
    call add(s:snippets_expand_stack, {
          \ 'begin_line' : begin_line,
          \ 'begin_patterns' : begin_patterns,
          \ 'end_line' : end_line,
          \ 'end_patterns' : end_patterns,
          \ 'holder_cnt' : 1,
          \ })

    if snip_word =~ s:get_placeholder_marker_pattern()
      call neosnippet#jump(a:cur_text, a:col)
    endif
  finally
    if has('folding')
      let &l:foldmethod = foldmethod
      silent! execute begin_line . ',' . end_line . 'foldopen!'
    endif
  endtry

  let &l:iminsert = 0
  let &l:imsearch = 0
endfunction"}}}
function! neosnippet#expand_target() "{{{
  let trigger = input('Please input snippet trigger: ',
        \ '', 'customlist,neosnippet#complete_target_snippets')
  let neosnippet = neosnippet#get_current_neosnippet()
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
  let neosnippet = neosnippet#get_current_neosnippet()
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

  let neosnippet = neosnippet#get_current_neosnippet()

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

function! neosnippet#register_oneshot_snippet() "{{{
  let trigger = input('Please input snippet trigger: ', 'oneshot')
  if trigger == ''
    return
  endif

  let selected_text = substitute(
        \ neosnippet#get_selected_text(visualmode(), 1), '\n$', '', '')
  call neosnippet#delete_selected_text(visualmode(), 1)

  let base_indent = matchstr(selected_text, '^\s*')

  " Delete base_indent.
  let selected_text = substitute(selected_text,
        \'^' . base_indent, '', 'g')

  let neosnippet = neosnippet#get_current_neosnippet()
  let options = s:initialize_snippet_options()
  let options.word = 1

  let neosnippet.snippets[trigger] = s:initialize_snippet(
        \ { 'name' : trigger, 'word' : selected_text, 'options' : options },
        \ '', 0, '', trigger)

  echo 'Registered trigger : ' . trigger
endfunction"}}}

function! s:get_snippet_range(begin_line, begin_patterns, end_line, end_patterns) "{{{
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
function! s:search_snippet_range(start, end, cnt) "{{{
  call s:substitute_placeholder_marker(a:start, a:end, a:cnt)

  " Search marker pattern.
  let pattern = substitute(s:get_placeholder_marker_pattern(),
        \ '\\d\\+', a:cnt, '')

  for line in filter(range(a:start, a:end),
        \ 'getline(v:val) =~ pattern')
    call s:expand_placeholder(a:start, a:end, a:cnt, line)
    return 1
  endfor

  return 0
endfunction"}}}
function! s:search_outof_range(col) "{{{
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
function! s:expand_placeholder(start, end, holder_cnt, line) "{{{
  let pattern = substitute(s:get_placeholder_marker_pattern(),
        \ '\\d\\+', a:holder_cnt, '')
  let current_line = getline(a:line)
  let match = match(current_line, pattern)
  let neosnippet = neosnippet#get_current_neosnippet()

  let default_pattern = substitute(
        \ s:get_placeholder_marker_default_pattern(),
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
  if cnt >= 0
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

  if is_target
    " Expand target
    return s:expand_target_placeholder(a:line, match+1)
  endif

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
function! s:expand_target_placeholder(line, col) "{{{
  " Expand target
  let neosnippet = neosnippet#get_current_neosnippet()
  let next_line = getline(a:line)[a:col-1 :]
  let target_lines = split(neosnippet.target, '\n', 1)

  let cur_text = getline(a:line)[: a:col-2]
  let target_lines[0] = cur_text . target_lines[0]
  let next_col = len(target_lines[-1]) + 1
  let target_lines[-1] = target_lines[-1] . next_line

  let begin_line = a:line
  let end_line = a:line + len(target_lines) - 1

  if has('folding')
    let foldmethod = &l:foldmethod
    let &l:foldmethod = 'manual'
  endif

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
      let &l:foldmethod = foldmethod
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
          \ substitute(s:get_placeholder_marker_pattern(),
          \ '\\d\\+', '\\zs\\d\\+\\ze', ''))
    return search(substitute(
          \ s:get_mirror_placeholder_marker_pattern(),
          \ '\\d\\+', cnt, ''), 'nw') > 0 ? cnt : -1
  endif

  let pattern = substitute(
          \ s:get_mirror_placeholder_marker_pattern(),
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
function! neosnippet#get_current_neosnippet() "{{{
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
  call s:check_initialize()

  let neosnippet = neosnippet#get_current_neosnippet()
  let snippets = copy(neosnippet.snippets)
  for filetype in s:get_sources_filetypes(neosnippet#get_filetype())
    call neosnippet#make_cache(filetype)
    call extend(snippets, s:snippets[filetype], 'keep')
  endfor

  if mode() ==# 'i'
    " Special filters.
    let cur_text = neosnippet#util#get_cur_text()
    if !s:is_beginning_of_line(cur_text)
      call filter(snippets, '!v:val.options.head')
    endif

    call filter(snippets, "cur_text =~ get(v:val, 'regexp', '')")
  endif

  return snippets
endfunction"}}}
function! neosnippet#get_snippets_directory() "{{{
  call s:check_initialize()

  let snippets_dir = copy(s:snippets_dir)
  if !get(g:neosnippet#disable_runtime_snippets,
        \ neosnippet#get_filetype(),
        \ get(g:neosnippet#disable_runtime_snippets, '_', 0))
    let snippets_dir += s:runtime_dir
  endif

  return snippets_dir
endfunction"}}}
function! neosnippet#get_user_snippets_directory() "{{{
  call s:check_initialize()

  return copy(s:snippets_dir)
endfunction"}}}
function! neosnippet#get_runtime_snippets_directory() "{{{
  call s:check_initialize()

  return copy(s:runtime_dir)
endfunction"}}}
function! neosnippet#get_filetype() "{{{
  return exists('*neocomplcache#get_context_filetype') ?
        \ neocomplcache#get_context_filetype(1) :
        \ (&filetype == '' ? 'nothing' : &filetype)
endfunction"}}}
function! s:get_sources_filetypes(filetype) "{{{
  return (exists('*neocomplcache#get_source_filetypes') ?
        \ neocomplcache#get_source_filetypes(a:filetype) :
        \ [(a:filetype == '') ? 'nothing' : a:filetype]) + ['_']
endfunction"}}}

function! neosnippet#edit_complete(arglead, cmdline, cursorpos) "{{{
  return filter(s:neosnippet_options + neosnippet#filetype_complete(
        \ a:arglead, a:cmdline, a:cursorpos), 'stridx(v:val, a:arglead) == 0')
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

function! neosnippet#get_placeholder_target_marker_pattern() "{{{
  return '\${\d\+:TARGET\%(:.\{-}\)\?\\\@<!}'
endfunction"}}}
function! s:get_placeholder_marker_pattern() "{{{
  return '<`\d\+\%(:.\{-}\)\?\\\@<!`>'
endfunction"}}}
function! s:get_placeholder_marker_substitute_pattern() "{{{
  return '\${\(\d\+\%(:.\{-}\)\?\\\@<!\)}'
endfunction"}}}
function! s:get_placeholder_marker_default_pattern() "{{{
  return '<`\d\+:\zs.\{-}\ze\\\@<!`>'
endfunction"}}}
function! s:get_sync_placeholder_marker_pattern() "{{{
  return '<{\d\+\%(:.\{-}\)\?\\\@<!}>'
endfunction"}}}
function! s:get_sync_placeholder_marker_default_pattern() "{{{
  return '<{\d\+:\zs.\{-}\ze\\\@<!}>'
endfunction"}}}
function! s:get_mirror_placeholder_marker_pattern() "{{{
  return '<|\d\+|>'
endfunction"}}}
function! s:get_mirror_placeholder_marker_substitute_pattern() "{{{
  return '\$\(\d\+\)'
endfunction"}}}

function! s:SID_PREFIX() "{{{
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction"}}}

function! s:trigger(function) "{{{
  call s:check_initialize()

  let cur_text = neosnippet#util#get_cur_text()

  let col = col('.')
  let expr = ''
  if mode() !=# 'i'
    " Fix column.
    let col += 2
  endif

  " Get selected text.
  let neosnippet = neosnippet#get_current_neosnippet()
  let neosnippet.trigger = 1
  if mode() ==# 's' && neosnippet.selected_text =~ '^#:'
    let expr .= "a\<BS>"
  endif

  let expr .= printf("\<ESC>:call %s(%s,%d)\<CR>",
        \ a:function, string(cur_text), col)

  return expr
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

function! neosnippet#clear_select_mode_mappings() "{{{
  if !g:neosnippet#disable_select_mode_mappings
    return
  endif

  redir => mappings
    silent! smap
  redir END

  for line in map(filter(split(mappings, '\n'),
        \ "v:val !~# 'neosnippet\\|neocomplcache_snippets'"),
        \ "substitute(v:val, '<NL>', '<C-J>', 'g')")
    let map = matchstr(line, '^\a*\s*\zs\S\+')
    let map = substitute(map, '<NL>', '<C-j>', 'g')

    silent! execute 'sunmap' map
    silent! execute 'sunmap <buffer>' map
  endfor

  " Define default select mode mappings.
  snoremap <CR>     a<BS>
  snoremap <BS>     a<BS>
  snoremap <Del>    a<BS>
  snoremap <C-h>    a<BS>
  snoremap <right> <ESC>a
  snoremap <left>  <ESC>bi
endfunction"}}}

function! s:skip_next_auto_completion() "{{{
  " Skip next auto completion.
  if exists('*neocomplcache#skip_next_complete')
    call neocomplcache#skip_next_complete()
  endif

  let neosnippet = neosnippet#get_current_neosnippet()
  let neosnippet.trigger = 0
endfunction"}}}

function! s:on_insert_leave() "{{{
  " Get patterns and count.
  if empty(s:snippets_expand_stack)
        \ || neosnippet#get_current_neosnippet().trigger
    return
  endif

  let expand_info = s:snippets_expand_stack[-1]

  if expand_info.begin_line != expand_info.end_line
    return
  endif

  " Search patterns.
  let [begin, end] = s:get_snippet_range(
        \ expand_info.begin_line,
        \ expand_info.begin_patterns,
        \ expand_info.end_line,
        \ expand_info.end_patterns)

  let pos = getpos('.')
  try
    while s:search_snippet_range(begin, end, expand_info.holder_cnt)
      " Next count.
      let expand_info.holder_cnt += 1
    endwhile

    " Search placeholder 0.
    call s:search_snippet_range(begin, end, 0)

  finally
    stopinsert
    call setpos('.', pos)
  endtry
endfunction"}}}

if g:neosnippet#enable_snipmate_compatibility
  " For snipMate function.
  function! Filename(...)
    let filename = expand('%:t:r')
    if filename == ''
      return a:0 == 2 ? a:2 : ''
    elseif a:0 == 0 || a:1 == ''
      return filename
    else
      return substitute(a:1, '$1', filename, 'g')
    endif
  endfunction
endif

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
  return s:trigger('neosnippet#jump')
endfunction

function! s:initialize_script_variables() "{{{
  " Initialize.
  let s:snippets_expand_stack = []
  let s:snippets = {}

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
endfunction"}}}
function! s:initialize_cache() "{{{
  " Caching _ snippets.
  call neosnippet#make_cache('_')

  " Initialize check.
  call neosnippet#caching()
endfunction"}}}
function! s:initialize_others() "{{{
  augroup neosnippet "{{{
    autocmd!
    " Set caching event.
    autocmd FileType * call neosnippet#caching()
    " Recaching events
    autocmd BufWritePost *.snip,*.snippets
          \ call neosnippet#recaching()
    autocmd BufEnter *
          \ call neosnippet#clear_select_mode_mappings()
    autocmd InsertLeave * call s:on_insert_leave()
  augroup END"}}}

  augroup neosnippet
    autocmd BufNewFile,BufRead,Syntax *
          \ execute 'syntax match neosnippetExpandSnippets'
          \  "'".s:get_placeholder_marker_pattern(). '\|'
          \ .s:get_sync_placeholder_marker_pattern().'\|'
          \ .s:get_mirror_placeholder_marker_pattern()."'"
          \ 'containedin=ALL oneline'
    if has('conceal')
      autocmd BufNewFile,BufRead,Syntax *
            \ syntax region neosnippetConcealExpandSnippets
            \ matchgroup=neosnippetExpandSnippets
            \ start='<`\d\+:\=\|<{\d\+:\=\|<|'
            \ end='`>\|}>\||>'
            \ containedin=ALL
            \ concealends oneline
    endif
  augroup END
  doautocmd neosnippet BufRead

  hi def link neosnippetExpandSnippets Special

  if get(g:, 'loaded_echodoc', 0)
    call echodoc#register('snippets_complete', s:doc_dict)
  endif
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
