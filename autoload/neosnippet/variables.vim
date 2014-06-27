"=============================================================================
" FILE: variables.vim
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
function! neosnippet#variables#expand_stack() "{{{
  if !exists('s:expand_stack')
    let s:expand_stack = []
  endif

  return s:expand_stack
endfunction"}}}
function! neosnippet#variables#snippets() "{{{
  if !exists('s:snippets')
    let s:snippets= {}
  endif

  return s:snippets
endfunction"}}}
function! neosnippet#variables#set_snippets(list) "{{{
  if !exists('s:snippets')
    let s:snippets= {}
  endif

  let s:snippets = a:list
endfunction"}}}
function! neosnippet#variables#snippets_dir() "{{{
  if !exists('s:snippets_dir')
    let s:snippets_dir = []
  endif

  return s:snippets_dir
endfunction"}}}
function! neosnippet#variables#runtime_dir() "{{{
  if !exists('s:runtime_dir')
    let s:runtime_dir = []
  endif

  return s:runtime_dir
endfunction"}}}
function! neosnippet#variables#data_dir() "{{{
  let g:neosnippet#data_directory =
        \ substitute(fnamemodify(get(
        \   g:, 'neosnippet#data_directory',
        \  ($XDG_CACHE_DIR != '' ?
        \   $XDG_CACHE_DIR . '/neosnippet' : expand('~/.cache/neosnippet'))),
        \  ':p'), '\\', '/', 'g')
  if !isdirectory(g:neosnippet#data_directory)
    call mkdir(g:neosnippet#data_directory, 'p')
  endif

  return g:neosnippet#data_directory
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
