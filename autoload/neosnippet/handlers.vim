"=============================================================================
" FILE: handlers.vim
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

function! neosnippet#handlers#_complete_done() "{{{
  if empty(v:completed_item)
    return
  endif

  let snippets = neosnippet#helpers#get_snippets()
  if has_key(snippets, v:completed_item.word)
        \ && !get(snippets[v:completed_item.word], 'oneshot', 0)
    " Don't overwrite exists snippets
    return
  endif

  let item = v:completed_item

  let abbr = (item.abbr != '') ? item.abbr : item.word
  if len(item.menu) > 5
    " Combine menu.
    let abbr .= ' ' . item.menu
  endif

  if item.info != ''
    let abbr = split(item.info, '\n')[0]
  endif

  if abbr !~ '(.*)'
    return
  endif

  " Make snippet arguments
  let cnt = 1
  let snippet = item.word
  if snippet !~ '()\?$'
    let snippet .= '('
  endif
  for arg in split(matchstr(abbr, '(\zs.\{-}\ze)'), '[^[]\zs\s*,\s*')
    if cnt != 1
      let snippet .= ', '
    endif
    let snippet .= printf('${%d:#:%s}', cnt, escape(arg, '{}'))
    let cnt += 1
  endfor
  if snippet !~ ')$'
    let snippet .= ')'
  endif
  let snippet .= '${0}'

  let options = neosnippet#parser#_initialize_snippet_options()
  let options.word = 1
  let options.oneshot = 1

  let neosnippet = neosnippet#variables#current_neosnippet()
  let trigger = item.word
  let neosnippet.snippets[trigger] =
        \ neosnippet#parser#_initialize_snippet(
        \   { 'name' : trigger, 'word' : snippet, 'options' : options },
        \   '', 0, '', trigger)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
