"=============================================================================
" FILE: handlers.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

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
      stopinsert
    endwhile
  finally
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

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
