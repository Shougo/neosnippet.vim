Neosnippet
==========

The Neosnippet plug-In adds snippet support to Vim. Snippets are
small templates for commonly used code that you can fill in on the
fly. To use snippets can increase your productivity in Vim a lot.
The functionality of this plug-in is quite similar to plug-ins like
snipMate.vim or snippetsEmu.vim. But since you can choose snippets with the
[neocomplcache](https://github.com/Shougo/neocomplcache.vim) /
[neocomplete](https://github.com/Shougo/neocomplete.vim) interface, you might
have less trouble using them, because you do not have to remember each snippet
name.

Installation
------------

To install neosnippet and other Vim plug-ins it is recommended to use one of the
popular package managers for Vim, rather than installing by drag and drop all
required files into your `.vim` folder.

Notes:

* Vim 7.4 or above is needed.

* Default snippets files are available in:
  [neosnippet-snippets](https://github.com/Shougo/neosnippet-snippets)
* Installing default snippets is optional. If choose not to install them,
  you must deactivate them with `g:neosnippet#disable_runtime_snippets`.
* neocomplcache/neocomplete is not required to use neosnippet, but it's highly recommended.
* Extra snippets files can be found in:
  [vim-snippets](https://github.com/honza/vim-snippets).

### Manual (not recommended)

1. Install the
   [neocomplcache](https://github.com/Shougo/neocomplcache.vim)/
   [neocomplete](https://github.com/Shougo/neocomplete.vim) and
   [neosnippet-snippets](https://github.com/Shougo/neosnippet-snippets)
   first.
2. Put files in your Vim directory (usually `~/.vim/` or
   `%PROGRAMFILES%/Vim/vimfiles` on Windows).

### Vundle

1. Setup the [vundle](https://github.com/gmarik/vundle) package manager
2. Set the bundles for [neocomplcache](https://github.com/Shougo/neocomplcache)
   or [neocomplete](https://github.com/Shougo/neocomplete.vim)
   And [neosnippet](https://github.com/Shougo/neosnippet)
   And [neosnippet-snippets](https://github.com/Shougo/neosnippet-snippets)

    ```vim
    Plugin 'Shougo/neocomplcache'
    or
    Plugin 'Shougo/neocomplete'

    Plugin 'Shougo/neosnippet'
    Plugin 'Shougo/neosnippet-snippets'
    ```

3. Open up Vim and start installation with `:PluginInstall`

### Neobundle

1. Setup the [neobundle](https://github.com/Shougo/neobundle.vim) package manager
2. Set the bundles for [neocomplcache](https://github.com/Shougo/neocomplcache)
   or [neocomplete](https://github.com/Shougo/neocomplete.vim)
   And [neosnippet](https://github.com/Shougo/neosnippet)
   And [neosnippet-snippets](https://github.com/Shougo/neosnippet-snippets)

    ```vim
    NeoBundle 'Shougo/neocomplcache'
    or
    NeoBundle 'Shougo/neocomplete'

    NeoBundle 'Shougo/neosnippet'
    NeoBundle 'Shougo/neosnippet-snippets'
    ```

3. Open up Vim and start installation with `:NeoBundleInstall`

### VAM (vim-addon-manager)

1. Setup the [vim-addon-manager](https://github.com/MarcWeber/vim-addon-manager)
   package manager.
2. Add `neosnippet` to the list of addons in your vimrc:

    ```vim
    call vam#ActivateAddons(['neosnippet', 'neosnippet-snippets'])
    ```

    . Installation will start automatically when you open vim next time.

Configuration
-------------

This is an example `~/.vimrc` configuration for Neosnippet. It is assumed you
already have Neocomplcache configured. With the settings of the example, you
can use the following keys:

* `C-k` to select-and-expand a snippet from the Neocomplcache popup (Use `C-n`
  and `C-p` to select it). `C-k` can also be used to jump to the next field in
  the snippet.
* `Tab` to select the next field to fill in the snippet.

```vim
" Plugin key-mappings.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)

" SuperTab like snippets behavior.
" Note: It must be "imap" and "smap".  It uses <Plug> mappings.
"imap <expr><TAB>
" \ pumvisible() ? "\<C-n>" :
" \ neosnippet#expandable_or_jumpable() ?
" \    "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

" For conceal markers.
if has('conceal')
  set conceallevel=2 concealcursor=niv
endif
```

If you want to use a different collection of snippets than the
built-in ones, then you can set a path to the snippets with
the `g:neosnippet#snippets_directory` variable (e.g [Honza's
Snippets](https://github.com/honza/vim-snippets))

But if you enable `g:neosnippet#enable_snipmate_compatibility`, neosnippet will
load snipMate snippets from runtime path automatically.

```vim
" Enable snipMate compatibility feature.
let g:neosnippet#enable_snipmate_compatibility = 1

" Tell Neosnippet about the other snippets
let g:neosnippet#snippets_directory='~/.vim/bundle/vim-snippets/snippets'
```

