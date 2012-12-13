"=============================================================================
" FILE: snippet.vim
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

function! unite#sources#snippet#define() "{{{
  if !exists('*unite#version') || unite#version() < 150
    echoerr 'Your unite.vim is too old.'
    return []
  endif

  let kind = {
        \ 'name' : 'snippet',
        \ 'default_action' : 'expand',
        \ 'action_table': {},
        \ 'parents': ['jump_list', 'completion'],
        \ 'alias_table' : { 'edit' : 'open' },
        \ }
  call unite#define_kind(kind)

  return s:source
endfunction "}}}

" neosnippet source.
let s:source = {
      \ 'name': 'snippet',
      \ 'hooks' : {},
      \ 'action_table' : {},
      \ }

function! s:source.hooks.on_init(args, context) "{{{
  let a:context.source__cur_keyword_pos =
        \ s:get_keyword_pos(neosnippet#util#get_cur_text())
  let a:context.source__snippets =
        \ sort(values(neosnippet#get_snippets()))
endfunction"}}}

function! s:source.gather_candidates(args, context) "{{{
  let keyword_pos = a:context.source__cur_keyword_pos
  let list = []
  for keyword in a:context.source__snippets
    let dict = {
        \   'word' : keyword.word,
        \   'abbr' : printf('%-50s %s', keyword.word, keyword.menu),
        \   'kind': 'snippet',
        \   'action__complete_word' : keyword.word,
        \   'action__complete_pos' : keyword_pos,
        \   'action__path' : keyword.action__path,
        \   'action__pattern' : keyword.action__pattern,
        \   'source__menu' : keyword.menu,
        \   'source__snip' : keyword.snip,
        \   'source__snip_ref' : keyword,
        \ }

    call add(list, dict)
  endfor

  return list
endfunction "}}}

" Actions "{{{
let s:action_table = {}

let s:action_table.expand = {
      \ 'description' : 'expand snippet',
      \ }
function! s:action_table.expand.func(candidate) "{{{
  let cur_text = neosnippet#util#get_cur_text()
  let cur_keyword_str = matchstr(cur_text, '\S\+$')
  let context = unite#get_context()
  call neosnippet#expand(
        \ cur_text . a:candidate.action__complete_word[len(cur_keyword_str)],
        \ context.col, a:candidate.action__complete_word)
endfunction"}}}

let s:action_table.preview = {
      \ 'description' : 'preview snippet',
      \ 'is_selectable' : 1,
      \ 'is_quit' : 0,
      \ }
function! s:action_table.preview.func(candidates) "{{{
  for snip in a:candidates
    echohl String
    echo snip.action__complete_word
    echohl Special
    echo snip.source__menu
    echohl None
    echo snip.source__snip
    echo ' '
  endfor
endfunction"}}}

let s:action_table.unite__new_candidate = {
      \ 'description' : 'add new snippet',
      \ 'is_quit' : 1,
      \ }
function! s:action_table.unite__new_candidate.func(candidate) "{{{
  let trigger = unite#util#input('Please input snippet trigger: ')
  if trigger == ''
    echo 'Canceled.'
    return
  endif

  call unite#take_action('open', a:candidate)
  if &filetype != 'snippet'
    " Open failed.
    return
  endif

  if getline('$') != ''
    " Append line.
    call append('$', '')
  endif

  call append('$', [
        \ 'snippet     ' . trigger,
        \ 'abbr        ' . trigger,
        \ 'options     head',
        \ '    '
        \ ])

  call cursor(line('$'), 0)
  call cursor(0, col('$'))
endfunction"}}}


let s:source.action_table = s:action_table
unlet! s:action_table
"}}}

function! unite#sources#snippet#start_complete() "{{{
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

  return unite#start_complete(['snippet'],
        \ { 'input': neosnippet#util#get_cur_text(), 'buffer_name' : '' })
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
