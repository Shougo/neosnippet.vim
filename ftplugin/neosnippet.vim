"=============================================================================
" FILE: snippets.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

if !exists('b:undo_ftplugin')
    let b:undo_ftplugin = ''
else
    let b:undo_ftplugin = '|'
endif

setlocal expandtab
let &l:shiftwidth=&tabstop
let &l:softtabstop=&tabstop
let &l:commentstring="#%s"

let b:undo_ftplugin .= '
    \ setlocal expandtab< shiftwidth< softtabstop< tabstop< commentstring<
    \'

let &cpo = s:save_cpo
unlet s:save_cpo
