Neosnippet
==========

The Neosnippet plug-In adds snippet support to Vim. Snippets are
small templates for commonly used code that you can fill in on the
fly. To use snippets can increase your productivity in Vim a lot.
The functionality of this plug-in is quite similar to plug-ins like
snipMate.vim or snippetsEmu.vim. But since you can choose snippets with the
[Neocomplecache](https://github.com/Shougo/neocomplcache) interface, you might
have less trouble using them, because you do not have to remember each snippet
name.

Note: neocomplecache is NOT required! But recommended.

Installation
------------

To install neosnippet and other Vim plug-ins it is recommended to use one of the
popular package managers for Vim, rather than installing by drag and drop all
required files into your `.vim` folder.

### Manual (not recommended)

1. Install the [Neocomplecache](https://github.com/Shougo/neocomplcache) plugin first.
2. Put files in your Vim directory (usually `~/.vim/` or
   `%PROGRAMFILES%/Vim/vimfiles` on Windows).

### Vundle 

1. Setup the [vundle](https://github.com/gmarik/vundle) package manager 
2. Set the bundles for [Neocomplecache](https://github.com/Shougo/neocomplcache) and [Neobundle](https://github.com/Shougo/neosnippet) 

```
Bundle 'Shougo/neocomplcache.git'
Bundle 'Shougo/neosnippet.git'
```

3. Open up Vim and start installation with `:BundleInstall`

### Neobundle 

1. Setup the [neobundle](https://github.com/Shougo/neobundle.vim) package manager 
2. Set the bundles for [Neocomplecache](https://github.com/Shougo/neocomplcache) and [Neobundle](https://github.com/Shougo/neosnippet) 

```
NeoBundle 'Shougo/neocomplcache.git'
NeoBundle 'Shougo/neosnippet.git'
```

3. Open up Vim and start installation with `:NeoBundleInstall`

Configuration
-------------

This is an example `~/.vimrc` configuration for Neosnippet. It is assumes you
already have Neocomplecache configured. With the settings of the example, you
can use the following keys:

* `C-k` to select-and-expand a snippet from the Neocomplecache popup (Use `C-n`
  and `C-p` to select it). `C-k` can also be used to jump to the next field in
  the snippet.
* `Tab` to select the next field to fill in the snippet.

```vim
" Plugin key-mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)

" SuperTab like snippets behavior.
imap <expr><TAB> neosnippet#expandable_or_jumpable() ? "\<Plug>(neosnippet_expand_or_jump)" : pumvisible() ? "\<C-n>" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ? "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

" For snippet_complete marker.
if has('conceal')
  set conceallevel=2 concealcursor=i
endif

```

If you want to use a different collection of snippets than the
built-in ones, then you can set a path to the snippets with
the `g:neosnippet#snippets_directory` variable (e.g [Honza's
Snippets](https://github.com/honza/snipmate-snippets))

```vim
" Tell Neosnippet about the other snippets
let g:neosnippet#snippets_directory='~/.vim/bundle/snipmate-snippets/snippets'
```

