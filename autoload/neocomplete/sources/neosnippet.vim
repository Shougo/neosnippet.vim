"=============================================================================
" FILE: neosnippet.vim
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

let s:source = {
      \ 'name' : 'neosnippet',
      \ 'kind' : 'keyword',
      \ 'mark' : '[nsnip]',
      \ 'rank' : 8,
      \ 'hooks' : {},
      \ 'matchers' :
      \      (g:neocomplete#enable_fuzzy_completion ?
      \          ['matcher_fuzzy'] : ['matcher_head']),
      \}

function! s:source.gather_candidates(context) abort "{{{
  let snippets = values(neosnippet#helpers#get_completion_snippets())
  if matchstr(a:context.input, '\S\+$') !=#
        \ matchstr(a:context.input, '\w\+$')
    " Word filtering
    call filter(snippets, 'v:val.options.word')
  endif
  return snippets
endfunction"}}}

function! s:source.hooks.on_post_filter(context) abort "{{{
  for snippet in a:context.candidates
    let snippet.dup = 1
    let snippet.menu = neosnippet#util#strwidthpart(
          \ snippet.menu_template, winwidth(0)/3)
  endfor

  return a:context.candidates
endfunction"}}}

function! neocomplete#sources#neosnippet#define() abort "{{{
  return s:source
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
