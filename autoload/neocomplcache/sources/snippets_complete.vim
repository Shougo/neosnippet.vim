"=============================================================================
" FILE: snippets_complete.vim
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

let s:source = {
      \ 'name' : 'snippets_complete',
      \ 'kind' : 'complfunc',
      \ 'min_pattern_length' :
      \     g:neocomplcache_auto_completion_start_length,
      \}

function! s:source.initialize() "{{{
  " Initialize.
  call neocomplcache#set_dictionary_helper(
        \ g:neocomplcache_source_rank, 'snippets_complete', 8)
  call neocomplcache#set_completion_length('snippets_complete',
        \ g:neocomplcache_auto_completion_start_length)
  call neosnippet#util#set_default(
        \ 'g:neosnippet#enable_preview', 0)
endfunction"}}}

function! s:source.get_keyword_pos(cur_text) "{{{
  let cur_word = matchstr(a:cur_text, '\w\+$')
  let word_candidates = neocomplcache#keyword_filter(
        \ filter(values(neosnippet#helpers#get_snippets()),
        \ 'v:val.options.word'), cur_word)
  if !empty(word_candidates)
    return match(a:cur_text, '\w\+$')
  endif

  return match(a:cur_text, '\S\+$')
endfunction"}}}

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str) "{{{
  let list = s:keyword_filter(neosnippet#helpers#get_snippets(), a:cur_keyword_str)

  for snippet in list
    let snippet.dup = 1

    let snippet.menu = neosnippet#util#strwidthpart(
          \ snippet.menu_template, winwidth(0)/3)
    if g:neosnippet#enable_preview
      let snippet.info = snippet.snip
    endif
  endfor

  return list
endfunction"}}}

function! s:keyword_filter(snippets, cur_keyword_str) "{{{
  " Uniq by real_name.
  let dict = {}

  " Use default filter.
  let list = neocomplcache#keyword_filter(
        \ values(a:snippets), a:cur_keyword_str)

  " Add cur_keyword_str snippet.
  if has_key(a:snippets, a:cur_keyword_str)
    call add(list, a:snippets[a:cur_keyword_str])
  endif

  for snippet in neocomplcache#dup_filter(list)
    if !has_key(dict, snippet.real_name) ||
          \ len(dict[snippet.real_name].word) > len(snippet.word)
      let dict[snippet.real_name] = snippet
    endif
  endfor

  return values(dict)
endfunction"}}}

function! neocomplcache#sources#snippets_complete#define() "{{{
  return s:source
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
