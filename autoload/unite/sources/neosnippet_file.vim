"=============================================================================
" FILE: neosnippet_file.vim
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


function! unite#sources#neosnippet_file#define() "{{{
  return [s:source_user, s:source_runtime]
endfunction "}}}

" neosnippet source.
let s:source_user = {
      \ 'name': 'neosnippet/user',
      \ 'description' : 'neosnippet user file',
      \ 'action_table' : {},
      \ }

function! s:source_user.gather_candidates(args, context) "{{{
  return s:get_snippet_candidates(
        \ neosnippet#get_user_snippets_directory())
endfunction "}}}

let s:source_user.action_table.unite__new_candidate = {
      \ 'description' : 'create new user snippet',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 1,
      \ }
function! s:source_user.action_table.unite__new_candidate.func(candidate) "{{{
  let filename = input(
        \ 'New snippet file name: ', neosnippet#get_filetype())
  if filename != ''
    call neosnippet#edit_snippets(filename)
  endif
endfunction"}}}


" neosnippet source.
let s:source_runtime = {
      \ 'name': 'neosnippet/runtime',
      \ 'description' : 'neosnippet runtime file',
      \ 'action_table' : {},
      \ }

function! s:source_runtime.gather_candidates(args, context) "{{{
  return s:get_snippet_candidates(
        \ neosnippet#get_runtime_snippets_directory())
endfunction "}}}

let s:source_runtime.action_table.unite__new_candidate = {
      \ 'description' : 'create new runtime snippet',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 1,
      \ }
function! s:source_runtime.action_table.unite__new_candidate.func(candidate) "{{{
  let filename = input(
        \ 'New snippet file name: ', neosnippet#get_filetype())
  if filename != ''
    call neosnippet#edit_snippets('-runtime ' . filename)
  endif
endfunction"}}}


function! s:get_snippet_candidates(dirs) "{{{
  let _ = []
  for directory in a:dirs
    let _ += map(split(unite#util#substitute_path_separator(
          \ globpath(directory, '**/*.snip*')), '\n'), "{
          \    'word' : v:val[len(directory)+1 :],
          \    'action__path' : v:val,
          \    'kind' : 'file',
          \ }")
  endfor

  return _
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
