"=============================================================================
" FILE: snippet_target.vim
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

function! unite#sources#snippet_target#define() "{{{
  if !exists('*unite#version') || unite#version() < 150
    echoerr 'Your unite.vim is too old.'
    return []
  endif

  return s:source
endfunction "}}}

let s:source = {
      \ 'name': 'snippet/target',
      \ 'hooks' : {},
      \ 'default_action' : 'select',
      \ 'action_table' : {},
      \ 'is_listed' : 0,
      \ }

function! s:source.hooks.on_init(args, context) "{{{
  let a:context.source__bufnr = bufnr('%')
  let a:context.source__linenr = line('.')

  let a:context.source__snippets =
        \ sort(filter(values(neosnippet#get_snippets()),
        \    "v:val.snip =~# neosnippet#get_placeholder_target_marker_pattern()"))
endfunction"}}}

function! s:source.gather_candidates(args, context) "{{{
  let list = []
  for keyword in a:context.source__snippets
    let dict = {
        \   'word' : printf('%-50s %s', keyword.word, keyword.menu),
        \   'source__trigger' : keyword.word,
        \   'source__menu' : keyword.menu,
        \   'source__snip' : keyword.snip,
        \   'source__context' : a:context,
        \ }

    call add(list, dict)
  endfor

  return list
endfunction "}}}

" Actions "{{{
let s:source.action_table.select = {
      \ 'description' : 'select targetted snippet',
      \ }
function! s:source.action_table.select.func(candidate) "{{{
  let context = a:candidate.source__context
  if bufnr('%') != context.source__bufnr ||
        \ line('.') != context.source__linenr
    " Ignore.
    return
  endif

  call neosnippet#expand_target_trigger(a:candidate.source__trigger)
endfunction"}}}
"}}}

function! unite#sources#snippet_target#start() "{{{
  if !exists(':Unite')
    call neosnippet#util#print_error(
          \ 'unite.vim is not installed.')
    call neosnippet#util#print_error(
          \ 'Please install unite.vim Ver.1.5 or above.')
    return ''
  elseif unite#version() < 300
    call neosnippet#util#print_error(
          \ 'Your unite.vim is too old.')
    call neosnippet#util#print_error(
          \ 'Please install unite.vim Ver.3.0 or above.')
    return ''
  endif

  return unite#start_complete(['snippet/target'],
        \ { 'buffer_name' : 'snippet/target' })
endfunction "}}}

function! s:get_keyword_pos(cur_text) "{{{
  let cur_keyword_pos = match(a:cur_text, '\S\+$')
  if cur_keyword_pos < 0
    " Empty string.
    return len(a:cur_text)
  endif

  return cur_keyword_pos
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
