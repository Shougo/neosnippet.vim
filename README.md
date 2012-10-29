Neosnippet
==========

# Description

Neosnippet add snippet support to vim, using the [Neocomplecache](https://github.com/Shougo/neocomplcache) framework.

What is a snippet? It's a template for commonly used code that you can fill in on the fly.

# Installation

1. Install [Neocomplecache](https://github.com/Shougo/neocomplcache) first.
2. Put files in your Vim directory (usually `~/.vim/` or
   `%PROGRAMFILES%/Vim/vimfiles` on Windows).

# Configuration

Here is an example `~/.vimrc` configuration for Neosnippet.  It is assumed
you already have Neocomplecache configured.

With these settings, you will use the following keys:

* `C-k` to select-and-expand a snippet from the Neocomplecache popup (Use `C-n`
  and `C-p` to select it). `C-k` can also be used to jump to the next field in
  the snippet.
* `Tab` to select the next field to fill in the snippet.

```vim
" Plugin key-mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)

" SuperTab like snippets behavior.
imap <expr><TAB> neosnippet#expandable() ? "\<Plug>(neosnippet_expand_or_jump)" : pumvisible() ? "\<C-n>" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable() ? "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

" For snippet_complete marker.
if has('conceal')
  set conceallevel=2 concealcursor=i
endif

```

If you want to use a different collection of snippets other than the built-in
ones, such as [Honza's Snippets](https://github.com/honza/snipmate-snippets), then you
can set the `g:neosnippet#snippets_directory` variable.

```vim
" Tell Neosnippet about these snippets
let g:neosnippet#snippets_directory='~/.vim/bundle/snipmate-snippets/snippets'
```

