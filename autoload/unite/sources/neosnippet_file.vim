"=============================================================================
" FILE: neosnippet_file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 13 Dec 2012.
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
      \ }

function! s:source_user.gather_candidates(args, context) "{{{
  let files = s:snip_files(neosnippet#get_user_snippets_directory())
  return map(files, '{
\    "word" : v:val,
\    "action__path" : v:val,
\    "kind" : "file",
\  }')
endfunction "}}}


" neosnippet source.
let s:source_runtime = {
      \ 'name': 'neosnippet/runtime',
      \ 'description' : 'neosnippet runtime file',
      \ }

function! s:source_runtime.gather_candidates(args, context) "{{{
  let files = s:snip_files(neosnippet#get_runtime_snippets_directory())
  return map(files, '{
\    "word" : v:val,
\    "action__path" : v:val,
\    "kind" : "file",
\  }')
endfunction "}}}


function! s:snip_files(dirs) "{{{
  return eval(join(map(a:dirs, "split(globpath(v:val, '*.snip'), '\n')"),"+"))
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
