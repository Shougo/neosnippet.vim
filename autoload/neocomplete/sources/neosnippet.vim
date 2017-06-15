"=============================================================================
" FILE: neosnippet.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:source = {
      \ 'name' : 'neosnippet',
      \ 'kind' : 'keyword',
      \ 'mark' : '[nsnip]',
      \ 'rank' : 8,
      \ 'hooks' : {},
      \ 'matchers' :
      \      (g:neocomplete#enable_fuzzy_completion ?
      \          ['matcher_fuzzy'] : ['matcher_head']),
      \}

function! s:source.gather_candidates(context) abort "{{{
  let snippets = values(neosnippet#helpers#get_completion_snippets())
  if matchstr(a:context.input, '\S\+$') !=#
        \ matchstr(a:context.input, '\w\+$')
    " Word filtering
    call filter(snippets, 'v:val.options.word')
  endif
  return snippets
endfunction"}}}

function! s:source.hooks.on_post_filter(context) abort "{{{
  for snippet in a:context.candidates
    let snippet.dup = 1
    let snippet.menu = neosnippet#util#strwidthpart(
          \ snippet.menu_template, winwidth(0)/3)
  endfor

  return a:context.candidates
endfunction"}}}

function! neocomplete#sources#neosnippet#define() abort "{{{
  return s:source
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
