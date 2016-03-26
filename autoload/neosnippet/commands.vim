"=============================================================================
" FILE: commands.vim
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

" Variables  "{{{
let s:edit_options = [
      \ '-runtime',
      \ '-vertical', '-horizontal', '-direction=', '-split',
      \]
let s:Cache = neosnippet#util#get_vital().import('System.Cache.Deprecated')
"}}}

function! s:get_list() abort "{{{
  if !exists('s:List')
    let s:List = vital#of('neosnippet').import('Data.List')
  endif
  return s:List
endfunction"}}}

function! neosnippet#commands#_edit(args) abort "{{{
  if neosnippet#util#is_sudo()
    call neosnippet#util#print_error(
          \ '"sudo vim" is detected. This feature is disabled.')
    return
  endif

  call neosnippet#init#check()

  let [args, options] = neosnippet#util#parse_options(
        \ a:args, s:edit_options)

  let filetype = get(args, 0, '')
  if filetype == ''
    let filetype = neosnippet#helpers#get_filetype()
  endif

  let options = s:initialize_options(options)
  let snippet_dir = (options.runtime ?
        \ get(neosnippet#get_runtime_snippets_directory(), 0, '') :
        \ get(neosnippet#get_user_snippets_directory(), -1, ''))

  if snippet_dir == ''
    call neosnippet#util#print_error('Snippet directory is not found.')
    return
  endif

  if !isdirectory(snippet_dir) && !neosnippet#util#is_sudo()
    call mkdir(snippet_dir, 'p')
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
    execute 'edit' fnameescape(filename)
  catch /^Vim\%((\a\+)\)\=:E749/
  endtry
endfunction"}}}

function! neosnippet#commands#_make_cache(filetype) abort "{{{
  call neosnippet#init#check()

  let filetype = a:filetype == '' ?
        \ &filetype : a:filetype
  if filetype ==# ''
    let filetype = 'nothing'
  endif

  let snippets = neosnippet#variables#snippets()
  if has_key(snippets, filetype)
    return
  endif

  let snippets[filetype] = {}

  let path = join(neosnippet#helpers#get_snippets_directory(), ',')
  let cache_dir = neosnippet#variables#data_dir()

  for filename in s:get_snippets_files(path, filetype)
    " Clear cache file
    call s:Cache.deletefile(cache_dir, filename)
    let snippets[filetype] = extend(snippets[filetype],
          \ neosnippet#parser#_parse_snippets(filename))
  endfor

  if g:neosnippet#enable_snipmate_compatibility
    " Load file snippets
    for filename in s:get_snippet_files(path, filetype)
      let trigger = fnamemodify(filename, ':t:r')
      let snippets[filetype][trigger] =
            \ neosnippet#parser#_parse_snippet(filename, trigger)
    endfor
  endif
endfunction"}}}

function! neosnippet#commands#_source(filename) abort "{{{
  call neosnippet#init#check()

  let neosnippet = neosnippet#variables#current_neosnippet()
  let neosnippet.snippets = extend(neosnippet.snippets,
        \ neosnippet#parser#_parse_snippets(a:filename))
endfunction"}}}

function! neosnippet#commands#_clear_markers() abort "{{{
  let expand_stack = neosnippet#variables#expand_stack()

  " Get patterns and count.
  if !&l:modifiable || !&l:modified
        \ || empty(expand_stack)
        \ || neosnippet#variables#current_neosnippet().trigger
    return
  endif

  call neosnippet#view#_clear_markers(expand_stack[-1])
endfunction"}}}

" Complete helpers.
function! neosnippet#commands#_edit_complete(arglead, cmdline, cursorpos) abort "{{{
  return filter(s:edit_options +
        \ neosnippet#commands#_filetype_complete(a:arglead, a:cmdline, a:cursorpos),
        \ 'stridx(v:val, a:arglead) == 0')
endfunction"}}}
function! neosnippet#commands#_filetype_complete(arglead, cmdline, cursorpos) abort "{{{
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
function! neosnippet#commands#_complete_target_snippets(arglead, cmdline, cursorpos) abort "{{{
  return map(filter(values(neosnippet#helpers#get_snippets()),
        \ "stridx(v:val.word, a:arglead) == 0
        \ && v:val.snip =~# neosnippet#get_placeholder_target_marker_pattern()"), 'v:val.word')
endfunction"}}}

function! s:initialize_options(options) abort "{{{
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

function! s:get_snippets_files(path, filetype) abort "{{{
  let snippets_files = []
  for glob in s:get_list().flatten(
        \ map(split(get(g:neosnippet#scope_aliases,
        \   a:filetype, a:filetype), '\s*,\s*'), "
        \   [v:val.'.snip', v:val.'.snippets',
        \    v:val.'/**/*.snip', v:val.'/**/*.snippets']
        \ + (a:filetype != '_' &&
        \    !has_key(g:neosnippet#scope_aliases, a:filetype) ?
        \    [v:val . '_*.snip', v:val . '_*.snippets'] : [])"))
    let snippets_files += split(globpath(a:path, glob), '\n')
  endfor
  return reverse(s:get_list().uniq(snippets_files))
endfunction"}}}
function! s:get_snippet_files(path, filetype) abort "{{{
  let snippet_files = []
  for glob in s:get_list().flatten(
        \ map(split(get(g:neosnippet#scope_aliases,
        \   a:filetype, a:filetype), '\s*,\s*'), "
        \   [v:val.'/*.snippet']"))
    let snippet_files += split(globpath(a:path, glob), '\n')
  endfor
  return reverse(s:get_list().uniq(snippet_files))
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
