"=============================================================================
" FILE: util.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
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
function! neosnippet#util#get_vital() "{{{
  return s:V
endfunction"}}}
function! s:get_prelude() "{{{
  if !exists('s:Prelude')
    let s:Prelude = neosnippet#util#get_vital().import('Prelude')
  endif
  return s:Prelude
endfunction"}}}
function! s:get_list() "{{{
  if !exists('s:List')
    let s:List = neosnippet#util#get_vital().import('Data.List')
  endif
  return s:List
endfunction"}}}
function! s:get_process() "{{{
  if !exists('s:Process')
    let s:Process = neosnippet#util#get_vital().import('Process')
  endif
  return s:Process
endfunction"}}}

function! neosnippet#util#substitute_path_separator(...) "{{{
  return call(s:get_prelude().substitute_path_separator, a:000)
endfunction"}}}
function! neosnippet#util#system(...) "{{{
  return call(s:get_process().system, a:000)
endfunction"}}}
function! neosnippet#util#has_vimproc(...) "{{{
  return call(s:get_process().has_vimproc, a:000)
endfunction"}}}
function! neosnippet#util#is_windows(...) "{{{
  return call(s:get_prelude().is_windows, a:000)
endfunction"}}}
function! neosnippet#util#is_mac(...) "{{{
  return call(s:get_prelude().is_mac, a:000)
endfunction"}}}
function! neosnippet#util#get_last_status(...) "{{{
  return call(s:get_process().get_last_status, a:000)
endfunction"}}}
function! neosnippet#util#escape_pattern(...) "{{{
  return call(s:get_prelude().escape_pattern, a:000)
endfunction"}}}
function! neosnippet#util#iconv(...) "{{{
  return call(s:get_process().iconv, a:000)
endfunction"}}}
function! neosnippet#util#truncate(...) "{{{
  return call(s:get_prelude().truncate, a:000)
endfunction"}}}
function! neosnippet#util#strwidthpart(...) "{{{
  return call(s:get_prelude().strwidthpart, a:000)
endfunction"}}}

function! neosnippet#util#expand(path) "{{{
  return neosnippet#util#substitute_path_separator(
        \ expand(escape(a:path, '*?[]"={}'), 1))
endfunction"}}}
function! neosnippet#util#set_default(var, val, ...)  "{{{
  if !exists(a:var)
    let {a:var} = a:val
  endif
endfunction"}}}
function! neosnippet#util#set_dictionary_helper(...) "{{{
  return call(s:get_prelude().set_dictionary_helper, a:000)
endfunction"}}}

function! neosnippet#util#get_cur_text() "{{{
  return
        \ (mode() ==# 'i' ? (col('.')-1) : col('.')) >= len(getline('.')) ?
        \      getline('.') :
        \      matchstr(getline('.'),
        \         '^.*\%' . col('.') . 'c' . (mode() ==# 'i' ? '' : '.'))
endfunction"}}}
function! neosnippet#util#print_error(string) "{{{
  echohl Error | echomsg a:string | echohl None
endfunction"}}}

function! neosnippet#util#parse_options(args, options_list) "{{{
  let args = []
  let options = {}
  for arg in split(a:args, '\%(\\\@<!\s\)\+')
    let arg = substitute(arg, '\\\( \)', '\1', 'g')

    let matched_list = filter(copy(a:options_list),
          \  'stridx(arg, v:val) == 0')
    for option in matched_list
      let key = substitute(substitute(option, '-', '_', 'g'), '=$', '', '')[1:]
      let options[key] = (option =~ '=$') ?
            \ arg[len(option) :] : 1
      break
    endfor

    if empty(matched_list)
      call add(args, arg)
    endif
  endfor

  return [args, options]
endfunction"}}}

" Sudo check.
function! neosnippet#util#is_sudo() "{{{
  return $SUDO_USER != '' && $USER !=# $SUDO_USER
      \ && $HOME !=# expand('~'.$USER)
      \ && $HOME ==# expand('~'.$SUDO_USER)
endfunction"}}}

function! neosnippet#util#option2list(str) "{{{
  return type(a:str) == type('') ? split(a:str, '\s*,\s*') : a:str
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
