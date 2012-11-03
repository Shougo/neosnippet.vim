"=============================================================================
" FILE: syntax/snippet.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 15 Sep 2010
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

if version < 700
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn region  neosnippetString               start=+'+ end=+'+ contained
syn region  neosnippetString               start=+"+ end=+"+ contained
syn region  neosnippetEval                 start=+\\\@<!`+ end=+\\\@<!`+ contained
syn match   neosnippetWord                 '^\s\+.*$' contains=
      \neosnippetEval,neosnippetPlaceHolder,neosnippetEscape,neosnippetVariable
syn match   neosnippetPlaceHolder          '\${\d\+\%(:.\{-}\)\?\\\@<!}'
      \ contained contains=neosnippetPlaceHolderComment
syn match   neosnippetVariable             '\$\d\+' contained
syn match   neosnippetComment              '^#.*$'
syn match   neosnippetEscape               '\\[`]' contained

syn match   neosnippetKeyword
      \ '^\%(include\|snippet\|abbr\|prev_word\|delete\|alias\|options\|regexp\|TARGET\)' contained
syn keyword   neosnippetOption             head word contained
syn match   neosnippetPrevWords            '^prev_word\s\+.*$' contains=neosnippetString,neosnippetKeyword
syn match   neosnippetRegexpr              '^regexp\s\+.*$' contains=neosnippetString,neosnippetKeyword
syn match   neosnippetStatementName        '^snippet\s.*$' contains=neosnippetName,neosnippetKeyword
syn match   neosnippetName                 '\s\+.*$' contained
syn match   neosnippetStatementAbbr        '^abbr\s.*$' contains=neosnippetAbbr,neosnippetKeyword
syn match   neosnippetAbbr                 '\s\+.*$' contained
syn match   neosnippetStatementRank        '^rank\s.*$' contains=neosnippetRank,neosnippetKeyword
syn match   neosnippetRank                 '\s\+\d\+$' contained
syn match   neosnippetStatementInclude     '^include\s.*$' contains=neosnippetInclude,neosnippetKeyword
syn match   neosnippetInclude              '\s\+.*$' contained
syn match   neosnippetStatementDelete      '^delete\s.*$' contains=neosnippetDelete,neosnippetKeyword
syn match   neosnippetDelete               '\s\+.*$' contained
syn match   neosnippetStatementAlias       '^alias\s.*$' contains=neosnippetAlias,neosnippetKeyword
syn match   neosnippetAlias                '\s\+.*$' contained
syn match   neosnippetStatementOptions     '^options\s.*$' contains=neosnippetOption,neosnippetKeyword
syn match   neosnippetPlaceHolderComment   '{\d\+:\zs#:.\{-}\ze\\\@<!}' contained

hi def link neosnippetKeyword Statement
hi def link neosnippetString String
hi def link neosnippetName Identifier
hi def link neosnippetAbbr Normal
hi def link neosnippetEval Type
hi def link neosnippetWord String
hi def link neosnippetPlaceHolder Special
hi def link neosnippetPlaceHolderComment Comment
hi def link neosnippetVariable Special
hi def link neosnippetComment Comment
hi def link neosnippetInclude PreProc
hi def link neosnippetDelete PreProc
hi def link neosnippetOption PreProc
hi def link neosnippetAlias Identifier
hi def link neosnippetEscape Special

let b:current_syntax = "snippet"

let &cpo = s:save_cpo
unlet s:save_cpo
