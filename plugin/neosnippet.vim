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

if exists('g:loaded_neosnippet')
  finish
elseif v:version < 702
  echoerr 'neosnippet does not work this version of Vim "' . v:version . '".'
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Obsolute options check. "{{{
"}}}

" Plugin key-mappings. "{{{
inoremap <silent><expr> <Plug>(neosnippet_expand_or_jump)
      \ neosnippet#mappings#expand_or_jump_impl()
inoremap <silent><expr> <Plug>(neosnippet_jump_or_expand)
      \ neosnippet#mappings#jump_or_expand_impl()
inoremap <silent><expr> <Plug>(neosnippet_expand)
      \ neosnippet#mappings#expand_impl()
inoremap <silent><expr> <Plug>(neosnippet_jump)
      \ neosnippet#mappings#jump_impl()
snoremap <silent><expr> <Plug>(neosnippet_expand_or_jump)
      \ neosnippet#mappings#expand_or_jump_impl()
snoremap <silent><expr> <Plug>(neosnippet_jump_or_expand)
      \ neosnippet#mappings#jump_or_expand_impl()
snoremap <silent><expr> <Plug>(neosnippet_expand)
      \ neosnippet#mappings#expand_impl()
snoremap <silent><expr> <Plug>(neosnippet_jump)
      \ neosnippet#mappings#jump_impl()

xnoremap <silent> <Plug>(neosnippet_get_selected_text)
      \ :call neosnippet#helpers#get_selected_text(visualmode(), 1)<CR>

xnoremap <silent> <Plug>(neosnippet_expand_target)
      \ :<C-u>call neosnippet#mappings#_expand_target()<CR>
xnoremap <silent> <Plug>(neosnippet_register_oneshot_snippet)
      \ :<C-u>call neosnippet#mappings#_register_oneshot_snippet()<CR>

inoremap <expr><silent> <Plug>(neosnippet_start_unite_snippet)
      \ unite#sources#neosnippet#start_complete()
"}}}

augroup neosnippet "{{{
  autocmd InsertEnter * call neosnippet#init#_initialize()
augroup END"}}}

" Commands. "{{{
command! -nargs=? -complete=customlist,neosnippet#commands#_edit_complete
      \ NeoSnippetEdit
      \ call neosnippet#commands#_edit(<q-args>)

command! -nargs=? -complete=customlist,neosnippet#commands#_filetype_complete
      \ NeoSnippetMakeCache
      \ call neosnippet#commands#_make_cache(<q-args>)

command! -nargs=1 -complete=file
      \ NeoSnippetSource
      \ call neosnippet#commands#_source(<q-args>)

command! NeoSnippetClearMarkers
      \ call neosnippet#commands#_clear_markers()
"}}}

let g:loaded_neosnippet = 1

let &cpo = s:save_cpo
unlet s:save_cpo

" __END__
" vim: foldmethod=marker
