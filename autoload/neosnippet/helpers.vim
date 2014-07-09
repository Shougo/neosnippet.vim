"=============================================================================
" FILE: helpers.vim
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

function! neosnippet#helpers#get_cursor_snippet(snippets, cur_text) "{{{
  let cur_word = matchstr(a:cur_text, '\S\+$')
  if cur_word != '' && has_key(a:snippets, cur_word)
      return cur_word
  endif

  while cur_word != ''
    if has_key(a:snippets, cur_word) &&
          \ a:snippets[cur_word].options.word
      return cur_word
    endif

    let cur_word = substitute(cur_word, '^\%(\w\+\|\W\)', '', '')
  endwhile

  return cur_word
endfunction"}}}

function! neosnippet#helpers#get_snippets() "{{{
  call neosnippet#init#check()

  let neosnippet = neosnippet#variables#current_neosnippet()
  let snippets = copy(neosnippet.snippets)
  for filetype in s:get_sources_filetypes(neosnippet#helpers#get_filetype())
    call neosnippet#commands#_make_cache(filetype)
    call extend(snippets,
          \ neosnippet#variables#snippets()[filetype], 'keep')
  endfor

  let cur_text = neosnippet#util#get_cur_text()

  if mode() ==# 'i'
    " Special filters.
    if !s:is_beginning_of_line(cur_text)
      call filter(snippets, '!v:val.options.head')
    endif
  endif

  call filter(snippets, "cur_text =~# get(v:val, 'regexp', '')")

  return snippets
endfunction"}}}

function! neosnippet#helpers#get_snippets_directory() "{{{
  let snippets_dir = copy(neosnippet#variables#snippets_dir())
  if !get(g:neosnippet#disable_runtime_snippets,
        \ neosnippet#helpers#get_filetype(),
        \ get(g:neosnippet#disable_runtime_snippets, '_', 0))
    let snippets_dir += neosnippet#variables#runtime_dir()
  endif

  return snippets_dir
endfunction"}}}

function! neosnippet#helpers#get_filetype() "{{{
  if !exists('s:exists_context_filetype')
    " context_filetype.vim installation check.
    try
      call context_filetype#version()
      let s:exists_context_filetype = 1
    catch
      let s:exists_context_filetype = 0
    endtry
  endif

  let context_filetype =
        \ s:exists_context_filetype ?
        \ context_filetype#get_filetype() : &filetype
  if context_filetype == ''
    let context_filetype = 'nothing'
  endif

  return context_filetype
endfunction"}}}

function! neosnippet#helpers#get_selected_text(type, ...) "{{{
  let sel_save = &selection
  let &selection = 'inclusive'
  let reg_save = @@
  let pos = getpos('.')

  try
    " Invoked from Visual mode, use '< and '> marks.
    if a:0
      silent exe "normal! `<" . a:type . "`>y"
    elseif a:type == 'line'
      silent exe "normal! '[V']y"
    elseif a:type == 'block'
      silent exe "normal! `[\<C-v>`]y"
    else
      silent exe "normal! `[v`]y"
    endif

    return @@
  finally
    let &selection = sel_save
    let @@ = reg_save
    call setpos('.', pos)
  endtry
endfunction"}}}
function! neosnippet#helpers#delete_selected_text(type, ...) "{{{
  let sel_save = &selection
  let &selection = 'inclusive'
  let reg_save = @@
  let pos = getpos('.')

  try
    " Invoked from Visual mode, use '< and '> marks.
    if a:0
      silent exe "normal! `<" . a:type . "`>d"
    elseif a:type ==# 'V'
      silent exe "normal! `[V`]s"
    elseif a:type ==# "\<C-v>"
      silent exe "normal! `[\<C-v>`]d"
    else
      silent exe "normal! `[v`]d"
    endif
  finally
    let &selection = sel_save
    let @@ = reg_save
    call setpos('.', pos)
  endtry
endfunction"}}}
function! neosnippet#helpers#substitute_selected_text(type, text) "{{{
  let sel_save = &selection
  let &selection = 'inclusive'
  let reg_save = @@
  let pos = getpos('.')

  try
    " Invoked from Visual mode, use '< and '> marks.
    if a:0
      silent exe "normal! `<" . a:type . "`>s" . a:text
    elseif a:type ==# 'V'
      silent exe "normal! '[V']hs" . a:text
    elseif a:type ==# "\<C-v>"
      silent exe "normal! `[\<C-v>`]s" . a:text
    else
      silent exe "normal! `[v`]s" . a:text
    endif
  finally
    let &selection = sel_save
    let @@ = reg_save
    call setpos('.', pos)
  endtry
endfunction"}}}

function! s:is_beginning_of_line(cur_text) "{{{
  let keyword_pattern = '\S\+'
  let cur_keyword_str = matchstr(a:cur_text, keyword_pattern.'$')
  let line_part = a:cur_text[: -1-len(cur_keyword_str)]
  let prev_word_end = matchend(line_part, keyword_pattern)

  return prev_word_end <= 0
endfunction"}}}

function! s:get_sources_filetypes(filetype) "{{{
  let filetypes =
        \ exists('*neocomplete#get_source_filetypes') ?
        \   neocomplete#get_source_filetypes(a:filetype) :
        \ exists('*neocomplcache#get_source_filetypes') ?
        \   neocomplcache#get_source_filetypes(a:filetype) :
        \ split(((a:filetype == '') ? 'nothing' : a:filetype), '\.')
  return filetypes + ['_']
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
