"=============================================================================
" FILE: snippets.vim
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

" Only load this indent file when no other was loaded.
if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

let s:save_cpo = &cpo
set cpo&vim

if !exists('b:undo_indent')
    let b:undo_indent = ''
else
    let b:undo_indent .= '|'
endif

let b:undo_indent .= 'setlocal
    \ indentexpr<
    \ autoindent<
    \ indentkeys<
    \'

setlocal indentexpr=SnippetsIndent()
setlocal autoindent
setlocal indentkeys=o,O,=abbr\ ,=prev_word\ ,=alias\ ,=options\ ,=regexp\ ,!^F

function! SnippetsIndent() abort "{{{
    let line = getline('.')
    let prev_line = (line('.') == 1)? '' : getline(line('.')-1)

    if s:is_empty(prev_line)
        return 0
    endif

    "for indentkeys o,O
    if s:is_empty(line)
        if s:is_syntax(prev_line)
            return shiftwidth()
        else
            return -1
        endif
    "for indentkeys =words
    else
        if s:is_syntax(line) && s:is_syntax(prev_line)
            return 0
        else
            return -1
        endif
    endif
endfunction"}}}

function! s:is_empty(line)
    return a:line =~ '\v^\s*$'
endfunction

function! s:is_syntax(line)
    return a:line =~ '\v^\s*%(snippet|abbr|prev_word|alias|options|regexp)\s'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
