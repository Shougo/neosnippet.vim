"=============================================================================
" FILE: neosnippet.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 20 Jan 2013.
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
      \ neosnippet#expand_or_jump_impl()
inoremap <silent><expr> <Plug>(neosnippet_jump_or_expand)
      \ neosnippet#jump_or_expand_impl()
inoremap <silent><expr> <Plug>(neosnippet_expand)
      \ neosnippet#expand_impl()
inoremap <silent><expr> <Plug>(neosnippet_jump)
      \ neosnippet#jump_impl()
snoremap <silent><expr> <Plug>(neosnippet_expand_or_jump)
      \ neosnippet#expand_or_jump_impl()
snoremap <silent><expr> <Plug>(neosnippet_jump_or_expand)
      \ neosnippet#jump_or_expand_impl()
snoremap <silent><expr> <Plug>(neosnippet_expand)
      \ neosnippet#expand_impl()
snoremap <silent><expr> <Plug>(neosnippet_jump)
      \ neosnippet#jump_impl()

xnoremap <silent> <Plug>(neosnippet_get_selected_text)
      \ :call neosnippet#get_selected_text(visualmode(), 1)<CR>

imap <silent> <Plug>(neocomplcache_snippets_expand)
      \ <Plug>(neosnippet_expand_or_jump)
smap <silent> <Plug>(neocomplcache_snippets_expand)
      \ <Plug>(neosnippet_expand_or_jump)
imap <silent> <Plug>(neocomplcache_snippets_jump)
      \ <Plug>(neosnippet_jump_or_expand)
smap <silent> <Plug>(neocomplcache_snippets_jump)
      \ <Plug>(neosnippet_expand_or_jump)
imap <silent> <Plug>(neocomplcache_snippets_force_expand)
      \ <Plug>(neosnippet_expand)
smap <silent> <Plug>(neocomplcache_snippets_force_expand)
      \ <Plug>(neosnippet_expand)
imap <silent> <Plug>(neocomplcache_snippets_force_jump)
      \ <Plug>(neosnippet_jump)
smap <silent> <Plug>(neocomplcache_snippets_force_jump)
      \ <Plug>(neosnippet_jump)

xnoremap <silent> <Plug>(neosnippet_expand_target)
      \ :<C-u>call neosnippet#expand_target()<CR>
xnoremap <silent><expr> <Plug>(neosnippet_start_unite_snippet_target)
      \ unite#sources#snippet_target#start()
xnoremap <silent> <Plug>(neosnippet_register_oneshot_snippet)
      \ :<C-u>call neosnippet#register_oneshot_snippet()<CR>

imap <silent> <Plug>(neocomplcache_start_unite_snippet)
      \ <Plug>(neosnippet_start_unite_snippet)
inoremap <expr><silent> <Plug>(neosnippet_start_unite_snippet)
      \ unite#sources#snippet#start_complete()
"}}}

augroup neosnippet "{{{
    autocmd CursorHold,CursorMovedI
          \ * call neosnippet#_lazy_initialize()
augroup END"}}}

" Commands. "{{{
command! -nargs=? -complete=customlist,neosnippet#edit_complete
      \ NeoSnippetEdit
      \ call neosnippet#edit_snippets(<q-args>)

command! -nargs=? -complete=customlist,neosnippet#filetype_complete
      \ NeoSnippetMakeCache
      \ call neosnippet#make_cache(<q-args>)

command! -nargs=? -complete=customlist,neosnippet#filetype_complete
      \ NeoComplCacheCachingSnippets
      \ NeoSnippetMakeCache <args>
command! -nargs=? -complete=customlist,neosnippet#filetype_complete
      \ NeoComplCacheEditSnippets
      \ NeoSnippetEdit <args>
command! -nargs=? -complete=customlist,neosnippet#filetype_complete
      \ NeoComplCacheEditRuntimeSnippets
      \ NeoSnippetEdit -runtime <args>

command! -nargs=1 -complete=file
      \ NeoSnippetSource
      \ call neosnippet#source_file(<q-args>)
"}}}

let g:loaded_neosnippet = 1

let &cpo = s:save_cpo
unlet s:save_cpo

" __END__
" vim: foldmethod=marker
