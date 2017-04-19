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

" Global options definition. "{{{
call neosnippet#util#set_default(
      \ 'g:neosnippet#disable_runtime_snippets', {})
call neosnippet#util#set_default(
      \ 'g:neosnippet#scope_aliases', {})
call neosnippet#util#set_default(
      \ 'g:neosnippet#snippets_directory', '')
call neosnippet#util#set_default(
      \ 'g:neosnippet#disable_select_mode_mappings', 1)
call neosnippet#util#set_default(
      \ 'g:neosnippet#enable_snipmate_compatibility', 0)
call neosnippet#util#set_default(
      \ 'g:neosnippet#expand_word_boundary', 0)
call neosnippet#util#set_default(
      \ 'g:neosnippet#enable_conceal_markers', 1)
call neosnippet#util#set_default(
      \ 'g:neosnippet#enable_completed_snippet', 0,
      \ 'g:neosnippet#enable_complete_done')
call neosnippet#util#set_default(
      \ 'g:neosnippet#enable_auto_clear_markers', 1)
call neosnippet#util#set_default(
      \ 'g:neosnippet#completed_pairs', {})
call neosnippet#util#set_default(
      \ 'g:neosnippet#_completed_pairs',
      \ {'_':{ '(' : ')', '{' : '}', '"' : '"', '[' : ']' }})
"}}}

function! neosnippet#expandable_or_jumpable() abort "{{{
  return neosnippet#mappings#expandable_or_jumpable()
endfunction"}}}
function! neosnippet#expandable() abort "{{{
  return neosnippet#mappings#expandable()
endfunction"}}}
function! neosnippet#jumpable() abort "{{{
  return neosnippet#mappings#jumpable()
endfunction"}}}
function! neosnippet#anonymous(snippet) abort "{{{
  return neosnippet#mappings#_anonymous(a:snippet)
endfunction"}}}
function! neosnippet#expand(trigger) abort "{{{
  return neosnippet#mappings#_expand(a:trigger)
endfunction"}}}

function! neosnippet#get_snippets_directory() abort "{{{
  return neosnippet#helpers#get_snippets_directory()
endfunction"}}}
function! neosnippet#get_user_snippets_directory() abort "{{{
  return copy(neosnippet#variables#snippets_dir())
endfunction"}}}
function! neosnippet#get_runtime_snippets_directory() abort "{{{
  return copy(neosnippet#variables#runtime_dir())
endfunction"}}}

" Get marker patterns.
function! neosnippet#get_placeholder_target_marker_pattern() abort "{{{
  return '\%(\\\@<!\|\\\\\zs\)\${\d\+:\(#:\)\?TARGET\%(:.\{-}\)\?\\\@<!}'
endfunction"}}}
function! neosnippet#get_placeholder_marker_pattern() abort "{{{
  return '<`\d\+\%(:.\{-}\)\?\\\@<!`>'
endfunction"}}}
function! neosnippet#get_placeholder_marker_substitute_pattern() abort "{{{
  return '\%(\\\@<!\|\\\\\zs\)\${\(\d\+\%(:.\{-}\)\?\\\@<!\)}'
endfunction"}}}
function! neosnippet#get_placeholder_marker_substitute_nonzero_pattern() abort "{{{
  return '\%(\\\@<!\|\\\\\zs\)\${\([1-9]\d*\%(:.\{-}\)\?\\\@<!\)}'
endfunction"}}}
function! neosnippet#get_placeholder_marker_substitute_zero_pattern() abort "{{{
  return '\%(\\\@<!\|\\\\\zs\)\${\(0\%(:.\{-}\)\?\\\@<!\)}'
endfunction"}}}
function! neosnippet#get_placeholder_marker_default_pattern() abort "{{{
  return '<`\d\+:\zs.\{-}\ze\\\@<!`>'
endfunction"}}}
function! neosnippet#get_sync_placeholder_marker_pattern() abort "{{{
  return '<{\d\+\%(:.\{-}\)\?\\\@<!}>'
endfunction"}}}
function! neosnippet#get_sync_placeholder_marker_default_pattern() abort "{{{
  return '<{\d\+:\zs.\{-}\ze\\\@<!}>'
endfunction"}}}
function! neosnippet#get_mirror_placeholder_marker_pattern() abort "{{{
  return '<|\d\+|>'
endfunction"}}}
function! neosnippet#get_mirror_placeholder_marker_substitute_pattern() abort "{{{
  return '\\\@<!\$\(\d\+\)'
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
