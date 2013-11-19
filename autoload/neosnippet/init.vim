"=============================================================================
" FILE: init.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 Nov 2013.
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

function! neosnippet#init#_initialize() "{{{
  let s:is_initialized = 1

  call s:initialize_script_variables()
  call s:initialize_others()
  call s:initialize_cache()
endfunction"}}}

function! neosnippet#init#check() "{{{
  if !exists('s:is_initialized')
    call neosnippet#init#_initialize()
  endif
endfunction"}}}

function! s:initialize_script_variables() "{{{
  " Set runtime dir.
  let runtime_dir = neosnippet#variables#get_runtime_dir()
  let runtime_dir += split(globpath(&runtimepath,
        \ 'autoload/neosnippet/snippets'), '\n')
  if g:neosnippet#enable_snipmate_compatibility
    " Load snipMate snippet directories.
    let runtime_dir += split(globpath(&runtimepath,
          \ 'snippets'), '\n')
  endif
  let runtime_dir += (exists('g:snippets_dir') ?
        \ split(g:snippets_dir, '\s*,\s*')
        \ : split(globpath(&runtimepath, 'snippets'), '\n'))
  call map(runtime_dir, 'substitute(v:val, "[\\\\/]$", "", "")')

  " Set snippets_dir.
  let snippets_dir = neosnippet#variables#get_snippets_dir()
  for dir in neosnippet#util#option2list(g:neosnippet#snippets_directory)
    let dir = neosnippet#util#expand(dir)
    if !isdirectory(dir) && !neosnippet#util#is_sudo()
      call mkdir(dir, 'p')
    endif
    call add(snippets_dir, dir)
  endfor
  call map(snippets_dir, 'substitute(v:val, "[\\\\/]$", "", "")')
endfunction"}}}
function! s:initialize_cache() "{{{
  " Caching _ snippets.
  call neosnippet#make_cache('_')

  " Initialize check.
  call neosnippet#caching()
endfunction"}}}
function! s:initialize_others() "{{{
  augroup neosnippet "{{{
    autocmd!
    " Set caching event.
    autocmd FileType * call neosnippet#caching()
    " Recaching events
    autocmd BufWritePost *.snip,*.snippets
          \ call neosnippet#recaching()
    autocmd BufEnter *
          \ call neosnippet#mappings#_clear_select_mode_mappings()
    autocmd InsertLeave * call s:on_insert_leave()
  augroup END"}}}

  augroup neosnippet
    autocmd BufNewFile,BufRead,Syntax *
          \ execute 'syntax match neosnippetExpandSnippets'
          \  "'".neosnippet#get_placeholder_marker_pattern(). '\|'
          \ .neosnippet#get_sync_placeholder_marker_pattern().'\|'
          \ .neosnippet#get_mirror_placeholder_marker_pattern()."'"
          \ 'containedin=ALL oneline'
    if has('conceal')
      autocmd BufNewFile,BufRead,Syntax *
            \ syntax region neosnippetConcealExpandSnippets
            \ matchgroup=neosnippetExpandSnippets
            \ start='<`\d\+:\=\|<{\d\+:\=\|<|'
            \ end='`>\|}>\||>'
            \ containedin=ALL
            \ concealends oneline
    endif
  augroup END
  doautocmd neosnippet BufRead

  hi def link neosnippetExpandSnippets Special

  if get(g:, 'loaded_echodoc', 0)
    call echodoc#register('snippets_complete', s:doc_dict)
  endif

  call neosnippet#mappings#_clear_select_mode_mappings()
endfunction"}}}

function! s:on_insert_leave() "{{{
  let expand_stack = neosnippet#variables#get_expand_stack()

  " Get patterns and count.
  if empty(expand_stack)
        \ || neosnippet#get_current_neosnippet().trigger
    return
  endif

  let expand_info = expand_stack[-1]

  if expand_info.begin_line != expand_info.end_line
    return
  endif

  " Search patterns.
  let [begin, end] = neosnippet#_get_snippet_range(
        \ expand_info.begin_line,
        \ expand_info.begin_patterns,
        \ expand_info.end_line,
        \ expand_info.end_patterns)

  let pos = getpos('.')

  " Found snippet.
  let found = 0
  try
    while neosnippet#_search_snippet_range(begin, end, expand_info.holder_cnt, 0)
      " Next count.
      let expand_info.holder_cnt += 1
      let found = 1
    endwhile

    " Search placeholder 0.
    if neosnippet#_search_snippet_range(begin, end, 0)
      let found = 1
    endif
  finally
    if found
      stopinsert
    endif

    call setpos('.', pos)
  endtry
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
