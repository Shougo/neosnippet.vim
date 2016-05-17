"=============================================================================
" FILE: handlers.vim
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

function! neosnippet#handlers#_complete_done() abort "{{{
  if empty(v:completed_item)
        \ || !g:neosnippet#enable_completed_snippet
        \ || s:is_auto_pairs()
    return
  endif

  let snippet = neosnippet#parser#_get_completed_snippet(
        \ v:completed_item, neosnippet#util#get_next_text())
  if snippet == ''
    return
  endif

  let [cur_text, col, _] = neosnippet#mappings#_pre_trigger()
  call neosnippet#view#_insert(snippet, {}, cur_text, col)
endfunction"}}}

function! neosnippet#handlers#_cursor_moved() abort "{{{
  let expand_stack = neosnippet#variables#expand_stack()

  " Get patterns and count.
  if !&l:modifiable || !&l:modified
        \ || empty(expand_stack)
    return
  endif

  let expand_info = expand_stack[-1]
  if expand_info.begin_line == expand_info.end_line
        \ && line('.') != expand_info.begin_line
    call neosnippet#view#_clear_markers(expand_info)
  endif
endfunction"}}}

function! neosnippet#handlers#_all_clear_markers() abort "{{{
  if !&l:modifiable
    return
  endif

  let pos = getpos('.')

  try
    while !empty(neosnippet#variables#expand_stack())
      call neosnippet#view#_clear_markers(
            \ neosnippet#variables#expand_stack()[-1])
    endwhile
  finally
    stopinsert

    call setpos('.', pos)
  endtry
endfunction"}}}

function! neosnippet#handlers#_restore_unnamed_register() abort "{{{
  let neosnippet = neosnippet#variables#current_neosnippet()

  if neosnippet.unnamed_register != ''
        \ && @" !=# neosnippet.unnamed_register
    let @" = neosnippet.unnamed_register
    let neosnippet.unnamed_register = ''
  endif
endfunction"}}}

function! s:is_auto_pairs() abort "{{{
  return get(g:, 'neopairs#enable', 0)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
