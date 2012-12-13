"=============================================================================
" FILE: snippets_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 10 Nov 2012.
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

function! s:source.initialize() "{{{
  " Initialize.
  call neocomplcache#set_dictionary_helper(
        \ g:neocomplcache_source_rank, 'snippets_complete', 8)
  call neocomplcache#set_completion_length('snippets_complete',
        \ g:neocomplcache_auto_completion_start_length)
endfunction"}}}

function! s:source.get_keyword_pos(cur_text) "{{{
  let cur_word = matchstr(a:cur_text, '\w\+$')
  let word_candidates = neocomplcache#keyword_filter(
        \ filter(values(neosnippet#get_snippets()),
        \ 'v:val.options.word'), cur_word)
  if !empty(word_candidates)
    return match(a:cur_text, '\w\+$')
  endif

  return match(a:cur_text, '\S\+$')
endfunction"}}}

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str) "{{{
  let list = s:keyword_filter(neosnippet#get_snippets(), a:cur_keyword_str)

  " Substitute abbr.
  let abbr_pattern = printf('%%.%ds..%%s',
        \ g:neocomplcache_max_keyword_width-10)
  for snippet in list
    let snippet.dup = 1
    let snippet.neocomplcache__convertable = 0

    let snippet.kind = get(snippet,
          \ 'neocomplcache__refresh', 0) ? '~' : ''
  endfor

  return list
endfunction"}}}

function! s:keyword_filter(snippets, cur_keyword_str) "{{{
  " Uniq by real_name.
  let dict = {}

  " Use default filter.
  let list = neocomplcache#keyword_filter(
        \ values(a:snippets), a:cur_keyword_str)
  for snippet in list
    " reset refresh flag.
    let snippet.neocomplcache__refresh = 0
    let snippet.rank = 5
  endfor

  if len(a:cur_keyword_str) > 1 && a:cur_keyword_str =~ '^\h\w*$'
    " Use partial match by filter_str.
    let partial_list = filter(values(a:snippets),
          \  printf('stridx(v:val.filter_str, %s) > 0',
          \      string(a:cur_keyword_str)))
    for snippet in partial_list
      " Set refresh flag.
      let snippet.neocomplcache__refresh = 1
      let snippet.rank = 0
    endfor

    let list += partial_list
  endif

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

function! s:compare_words(i1, i2)
  return a:i1.menu - a:i2.menu
endfunction

function! neocomplcache#sources#snippets_complete#expandable() "{{{
  return neosnippet#expandable()
endfunction"}}}
function! neocomplcache#sources#snippets_complete#force_expandable() "{{{
  return neosnippet#expandable()
endfunction"}}}
function! neocomplcache#sources#snippets_complete#jumpable() "{{{
  return neosnippet#jumpable()
endfunction"}}}

function! neocomplcache#sources#snippets_complete#get_snippets() "{{{
  return neosnippet#get_snippets()
endfunction"}}}
function! neocomplcache#sources#snippets_complete#get_snippets_dir() "{{{
  return neosnippet#get_snippets_directory()
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
