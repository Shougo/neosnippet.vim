"=============================================================================
" FILE: neosnippet.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 27 Sep 2012.
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

if exists('g:loaded_neosnippet')
  finish
elseif v:version < 702
  echoerr 'neosnippet does not work this version of Vim "' . v:version . '".'
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Obsolute options check."{{{
"}}}
" Global options definition."{{{
"}}}

" Plugin key-mappings."{{{
imap <silent> <Plug>(neosnippet_expand_or_jump)
      \ <Plug>(neosnippet_expand_or_jump_impl)
smap <silent> <Plug>(neosnippet_expand_or_jump)
      \ <Plug>(neosnippet_expand_or_jump_impl)
imap <silent> <Plug>(neosnippet_jump_or_expand)
      \ <Plug>(neosnippet_jump_or_expand_impl)
smap <silent> <Plug>(neosnippet_jump_or_expand)
      \ <Plug>(neosnippet_jump_or_expand_impl)
imap <silent> <Plug>(neosnippet_expand)
      \ <Plug>(neosnippet_expand_impl)
smap <silent> <Plug>(neosnippet_expand)
      \ <Plug>(neosnippet_expand_impl)
imap <silent> <Plug>(neosnippet_jump)
      \ <Plug>(neosnippet_jump_impl)
smap <silent> <Plug>(neosnippet_jump)
      \ <Plug>(neosnippet_jump_impl)

imap <silent> <Plug>(neocomplcache_snippets_expand)
      \ <Plug>(neosnippet_expand_or_jump_impl)
smap <silent> <Plug>(neocomplcache_snippets_expand)
      \ <Plug>(neosnippet_expand_or_jump_impl)
imap <silent> <Plug>(neocomplcache_snippets_jump)
      \ <Plug>(neosnippet_jump_or_expand_impl)
smap <silent> <Plug>(neocomplcache_snippets_jump)
      \ <Plug>(neosnippet_jump_or_expand_impl)
imap <silent> <Plug>(neocomplcache_snippets_force_expand)
      \ <Plug>(neosnippet_expand_impl)
smap <silent> <Plug>(neocomplcache_snippets_force_expand)
      \ <Plug>(neosnippet_expand_impl)
imap <silent> <Plug>(neocomplcache_snippets_force_jump)
      \ <Plug>(neosnippet_jump_impl)
smap <silent> <Plug>(neocomplcache_snippets_force_jump)
      \ <Plug>(neosnippet_jump_impl)
"}}}

let g:loaded_neosnippet = 1

let &cpo = s:save_cpo
unlet s:save_cpo

" __END__
" vim: foldmethod=marker
