"=============================================================================
" FILE: neosnippet_file.vim
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

function! unite#sources#neosnippet_file#define() abort "{{{
  return [s:source_user, s:source_runtime]
endfunction "}}}

" common action table
let s:action_table = {}
let s:action_table.neosnippet_source = {
      \ 'description' : 'neosnippet_source file',
      \ 'is_selectable' : 1,
      \ 'is_quit' : 1,
      \ }
function! s:action_table.neosnippet_source.func(candidates) abort "{{{
  for candidate in a:candidates
    let snippet_name = candidate.action__path
    if snippet_name != ''
      call neosnippet#commands#_source(snippet_name)
    endif
  endfor
endfunction"}}}

" neosnippet source.
let s:source_user = {
      \ 'name': 'neosnippet/user',
      \ 'description' : 'neosnippet user file',
      \ 'action_table' : copy(s:action_table),
      \ }
function! s:source_user.gather_candidates(args, context) abort "{{{
  return s:get_snippet_candidates(
        \ neosnippet#get_user_snippets_directory())
endfunction "}}}

let s:source_user.action_table.unite__new_candidate = {
      \ 'description' : 'create new user snippet',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 1,
      \ }
function! s:source_user.action_table.unite__new_candidate.func(candidate) abort "{{{
  let filename = input(
        \ 'New snippet file name: ', neosnippet#helpers#get_filetype())
  if filename != ''
    call neosnippet#commands#_edit(filename)
  endif
endfunction"}}}


" neosnippet source.
let s:source_runtime = {
      \ 'name': 'neosnippet/runtime',
      \ 'description' : 'neosnippet runtime file',
      \ 'action_table' : copy(s:action_table),
      \ }
function! s:source_runtime.gather_candidates(args, context) abort "{{{
  return s:get_snippet_candidates(
        \ neosnippet#get_runtime_snippets_directory())
endfunction "}}}

let s:source_runtime.action_table.unite__new_candidate = {
      \ 'description' : 'create new runtime snippet',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 1,
      \ }
function! s:source_runtime.action_table.unite__new_candidate.func(candidate) abort "{{{
  let filename = input(
        \ 'New snippet file name: ', neosnippet#helpers#get_filetype())
  if filename != ''
    call neosnippet#commands#_edit('-runtime ' . filename)
  endif
endfunction"}}}


function! s:get_snippet_candidates(dirs) abort "{{{
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
