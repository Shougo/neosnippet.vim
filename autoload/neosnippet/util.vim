"=============================================================================
" FILE: util.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 30 Sep 2012.
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

let s:V = vital#of('neosnippet')

function! neosnippet#util#substitute_path_separator(...)"{{{
  return call(s:V.substitute_path_separator, a:000)
endfunction"}}}
function! neosnippet#util#system(...)"{{{
  return call(s:V.system, a:000)
endfunction"}}}
function! neosnippet#util#has_vimproc(...)"{{{
  return call(s:V.has_vimproc, a:000)
endfunction"}}}
function! neosnippet#util#is_windows(...)"{{{
  return call(s:V.is_windows, a:000)
endfunction"}}}
function! neosnippet#util#is_mac(...)"{{{
  return call(s:V.is_mac, a:000)
endfunction"}}}
function! neosnippet#util#get_last_status(...)"{{{
  return call(s:V.get_last_status, a:000)
endfunction"}}}
function! neosnippet#util#escape_pattern(...)"{{{
  return call(s:V.escape_pattern, a:000)
endfunction"}}}
function! neosnippet#util#iconv(...)"{{{
  return call(s:V.iconv, a:000)
endfunction"}}}

function! neosnippet#util#set_dictionary_helper(...)"{{{
  return call(s:V.set_dictionary_helper, a:000)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
