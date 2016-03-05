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

function! neosnippet#variables#current_neosnippet() abort "{{{
  if !exists('b:neosnippet')
    let b:neosnippet = {
          \ 'snippets' : {},
          \ 'selected_text' : '',
          \ 'target' : '',
          \ 'trigger' : 0,
          \ 'optional_tabstop' : 0,
          \ 'unnamed_register' : '',
          \}
  endif

  return b:neosnippet
endfunction"}}}
function! neosnippet#variables#expand_stack() abort "{{{
  if !exists('s:expand_stack')
    let s:expand_stack = []
  endif

  return s:expand_stack
endfunction"}}}
function! neosnippet#variables#pop_expand_stack() abort "{{{
  let s:expand_stack = s:expand_stack[: -2]
endfunction"}}}
function! neosnippet#variables#clear_expand_stack() abort "{{{
  let s:expand_stack = []
endfunction"}}}
function! neosnippet#variables#snippets() abort "{{{
  if !exists('s:snippets')
    let s:snippets= {}
  endif

  return s:snippets
endfunction"}}}
function! neosnippet#variables#set_snippets(list) abort "{{{
  if !exists('s:snippets')
    let s:snippets= {}
  endif

  let s:snippets = a:list
endfunction"}}}
function! neosnippet#variables#snippets_dir() abort "{{{
  " Set snippets_dir.
  let snippets_dir = map(neosnippet#util#option2list(
        \   g:neosnippet#snippets_directory),
        \ 'neosnippet#util#expand(v:val)')
  return map(snippets_dir, 'substitute(v:val, "[\\\\/]$", "", "")')
endfunction"}}}
function! neosnippet#variables#runtime_dir() abort "{{{
  " Set runtime dir.
  let runtime_dir = split(globpath(&runtimepath, 'neosnippets'), '\n')
  if empty(runtime_dir) && empty(g:neosnippet#disable_runtime_snippets)
    call neosnippet#util#print_error(
          \ 'neosnippet default snippets cannot be loaded.')
    call neosnippet#util#print_error(
          \ 'You must install neosnippet-snippets or disable runtime snippets.')
  endif
  if g:neosnippet#enable_snipmate_compatibility
    " Load snipMate snippet directories.
    let runtime_dir += split(globpath(&runtimepath,
          \ 'snippets'), '\n')
    if exists('g:snippets_dir')
      let runtime_dir += neosnippet#util#option2list(g:snippets_dir)
    endif
  endif

  return map(runtime_dir, 'substitute(v:val, "[\\\\/]$", "", "")')
endfunction"}}}
function! neosnippet#variables#data_dir() abort "{{{
  let g:neosnippet#data_directory =
        \ substitute(fnamemodify(get(
        \   g:, 'neosnippet#data_directory',
        \  ($XDG_CACHE_HOME != '' ?
        \   $XDG_CACHE_HOME . '/neosnippet' : expand('~/.cache/neosnippet'))),
        \  ':p'), '\\', '/', 'g')
  if !isdirectory(g:neosnippet#data_directory)
    call mkdir(g:neosnippet#data_directory, 'p')
  endif

  return g:neosnippet#data_directory
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
