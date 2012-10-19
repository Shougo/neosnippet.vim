"=============================================================================
" FILE: snippets_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 Oct 2012.
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
      \}

function! s:source.initialize()"{{{
  " Initialize.
  call neocomplcache#set_dictionary_helper(
        \ g:neocomplcache_source_rank, 'snippets_complete', 8)
  call neocomplcache#set_completion_length('snippets_complete',
        \ g:neocomplcache_auto_completion_start_length)
endfunction"}}}

function! s:source.get_keyword_pos(cur_text)"{{{
  return match(a:cur_text, '\S\+$')
endfunction"}}}

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
  return s:keyword_filter(neocomplcache#dup_filter(
        \ values(neosnippet#get_snippets())), a:cur_keyword_str)
endfunction"}}}

function! s:keyword_filter(list, cur_keyword_str)"{{{
  " Keyword filter.

  " Uniq by real_name.
  let dict = {}
  for snippet in neocomplcache#keyword_filter(a:list, a:cur_keyword_str)
    if !has_key(dict, snippet.real_name) ||
          \ len(dict[snippet.real_name].word) > len(snippet.word)
      let dict[snippet.real_name] = snippet
    endif
  endfor

  let list = values(dict)

  " Substitute abbr.
  let abbr_pattern = printf('%%.%ds..%%s',
        \ g:neocomplcache_max_keyword_width-10)
  for snippet in list
    if snippet.snip =~ '\\\@<!`=.*\\\@<!`'
      let snippet.menu = s:eval_snippet(snippet.snip)

      if g:neocomplcache_max_keyword_width >= 0 &&
            \ len(snippet.menu) > g:neocomplcache_max_keyword_width
        let snippet.menu = printf(abbr_pattern,
              \ snippet.menu, snippet.menu[-8:])
      endif
      let snippet.menu = '`Snip` ' . snippet.menu
    endif

    let snippet.neocomplcache__convertable = 0
  endfor

  return list
endfunction"}}}


function! neocomplcache#sources#snippets_complete#define()"{{{
  return s:source
endfunction"}}}

function! s:compare_words(i1, i2)
  return a:i1.menu - a:i2.menu
endfunction

function! neocomplcache#sources#snippets_complete#expandable()"{{{
  return neosnippet#expandable()
endfunction"}}}
function! neocomplcache#sources#snippets_complete#force_expandable()"{{{
  return neosnippet#expandable()
endfunction"}}}
function! neocomplcache#sources#snippets_complete#jumpable()"{{{
  return neosnippet#jumpable()
endfunction"}}}

function! neocomplcache#sources#snippets_complete#get_snippets()"{{{
  return neosnippet#get_snippets()
endfunction"}}}
function! neocomplcache#sources#snippets_complete#get_snippets_dir()"{{{
  return neosnippet#get_snippets_directory()
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
