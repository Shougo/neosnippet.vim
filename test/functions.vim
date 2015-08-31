let s:suite = themis#suite('toml')
let s:assert = themis#helper('assert')

function! s:suite.get_in_paren()
  call s:assert.equals(neosnippet#handlers#_get_in_paren('(foobar)'),
        \ 'foobar')
  call s:assert.equals(neosnippet#handlers#_get_in_paren('(foobar, baz)'),
        \ 'foobar, baz')
  call s:assert.equals(neosnippet#handlers#_get_in_paren('(foobar, (baz))'),
        \ 'foobar, (baz)')
endfunction

