"=============================================================================
" FILE: parser.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
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

let s:Cache = neosnippet#util#get_vital().import('System.Cache')

function! neosnippet#parser#_parse(snippet_file) "{{{
  if !filereadable(a:snippet_file)
    call neosnippet#util#print_error(
          \ printf('snippet file "%s" is not found.', a:snippet_file))
    return {}
  endif

  let cache_dir = neosnippet#variables#data_dir()
  if s:Cache.check_old_cache(cache_dir, a:snippet_file)
    let snippets = s:parse(a:snippet_file)
    if len(snippets) > 5
      call s:Cache.writefile(cache_dir, a:snippet_file, [string(snippets)])
    endif
  else
    sandbox let snippets = eval(s:Cache.readfile(cache_dir, a:snippet_file)[0])
  endif

  return snippets
endfunction"}}}

function! s:parse(snippet_file) "{{{
  let dup_check = {}
  let snippet_dict = {}
  let linenr = 1
  let snippets = {}

  for line in readfile(a:snippet_file)
    if line =~ '^\h\w*.*\s$'
      " Delete spaces.
      let line = substitute(line, '\s\+$', '', '')
    endif

    if line =~ '^#'
      " Ignore.
    elseif line =~ '^include'
      " Include snippets.
      let filename = matchstr(line, '^include\s\+\zs.*$')

      for snippet_file in split(globpath(join(
            \ neosnippet#helpers#get_snippets_directory(), ','),
            \ filename), '\n')
        let snippets = extend(snippets,
              \ neosnippet#parser#_parse(snippet_file))
      endfor
    elseif line =~ '^delete\s'
      let name = matchstr(line, '^delete\s\+\zs.*$')
      if name != '' && has_key(snippets, name)
        call filter(snippets, 'v:val.real_name !=# name')
      endif
    elseif line =~ '^snippet\s'
      if !empty(snippet_dict)
        " Set previous snippet.
        call s:set_snippet_dict(snippet_dict,
              \ snippets, dup_check, a:snippet_file)
      endif

      let snippet_dict = s:parse_snippet_name(
            \ a:snippet_file, line, linenr, dup_check)
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
              \ a:snippet_file, line, linenr, snippet_dict)
      endif
    endif

    let linenr += 1
  endfor

  if !empty(snippet_dict)
    " Set previous snippet.
    call s:set_snippet_dict(snippet_dict,
          \ snippets, dup_check, a:snippet_file)
  endif

  return snippets
endfunction"}}}

function! s:parse_snippet_name(snippet_file, line, linenr, dup_check) "{{{
  " Initialize snippet dict.
  let snippet_dict = { 'word' : '', 'linenr' : a:linenr,
        \ 'options' : neosnippet#parser#_initialize_snippet_options() }

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
          \ a:snippet_file, a:linenr, snippet_dict.name,
          \ dup.action__path, dup.action__line))
    call neosnippet#util#print_error(printf(
          \ 'Please rename the snippet name or use `delete %s`.',
          \ snippet_dict.name))
  endif

  return snippet_dict
endfunction"}}}

function! s:add_snippet_attribute(snippet_file, line, linenr, snippet_dict) "{{{
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
              \ printf('[neosnippet] %s:%d', a:snippet_file, a:linenr))
        call neosnippet#util#print_error(
              \ printf('[neosnippet] Invalid option name : "%s"', option))
      else
        let a:snippet_dict.options[option] = 1
      endif
    endfor
  else
    call neosnippet#util#print_error(
          \ printf('[neosnippet] %s:%d', a:snippet_file, a:linenr))
    call neosnippet#util#print_error(
          \ printf('[neosnippet] Invalid syntax : "%s"', a:line))
  endif
endfunction"}}}

function! s:set_snippet_dict(snippet_dict, snippets, dup_check, snippet_file) "{{{
  if empty(a:snippet_dict)
    return
  endif

  let action_pattern = '^snippet\s\+' . a:snippet_dict.name . '$'
  let snippet = neosnippet#parser#_initialize_snippet(
        \ a:snippet_dict, a:snippet_file,
        \ a:snippet_dict.linenr, action_pattern,
        \ a:snippet_dict.name)
  let a:snippets[a:snippet_dict.name] = snippet
  let a:dup_check[a:snippet_dict.name] = snippet

  for alias in get(a:snippet_dict, 'alias', [])
    let alias_snippet = copy(snippet)
    let alias_snippet.word = alias

    let a:snippets[alias] = alias_snippet
    let a:dup_check[alias] = alias_snippet
  endfor
endfunction"}}}

function! neosnippet#parser#_initialize_snippet(dict, path, line, pattern, name) "{{{
  let a:dict.word = substitute(a:dict.word, '\n\+$', '', '')
  if a:dict.word !~
        \ neosnippet#get_placeholder_marker_substitute_pattern()
    " Add placeholder.
    let a:dict.word .= '${0}'
  endif

  let menu_prefix = '[nsnip] '

  if !has_key(a:dict, 'abbr') || a:dict.abbr == ''
    " Set default abbr.
    let abbr = substitute(a:dict.word,
        \   neosnippet#get_placeholder_marker_pattern(). '\|'.
        \   neosnippet#get_mirror_placeholder_marker_pattern().
        \   '\|\s\+\|\n\|TARGET', ' ', 'g')
    let a:dict.abbr = a:dict.name
  else
    let abbr = a:dict.abbr
  endif

  let snippet = {
        \ 'word' : a:dict.name, 'snip' : a:dict.word,
        \ 'description' : a:dict.word,
        \ 'menu_template' : menu_prefix . abbr,
        \ 'menu_abbr' : abbr,
        \ 'options' : a:dict.options,
        \ 'action__path' : a:path, 'action__line' : a:line,
        \ 'action__pattern' : a:pattern, 'real_name' : a:name,
        \}

  if has_key(a:dict, 'regexp')
    let snippet.regexp = a:dict.regexp
  endif

  return snippet
endfunction"}}}

function! neosnippet#parser#_initialize_snippet_options() "{{{
  return { 'head' : 0, 'word' :
        \   g:neosnippet#expand_word_boundary, 'indent' : 0 }
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
