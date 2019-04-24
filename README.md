[![Build Status](https://travis-ci.org/AndrewRadev/tagalong.vim.svg?branch=master)](https://travis-ci.org/AndrewRadev/tagalong.vim)

![Tagalong](http://i.andrewradev.com/52e379b8425f731b215811c024683949.png)

## Basic Usage

The plugin is designed to automatically rename closing HTML/XML tags when editing opening ones (or the other way around). For the most part, you should be able to edit your code normally (see below for limitations) and the plugin would take care of the renaming once you leave insert mode:

![Demo](http://i.andrewradev.com/d31c94c2db184db8883726031deff69c.gif)

It only activates for particular filetypes. By default, those are: html, xml, jsx, eruby, ejs, eco, htmldjango.

You can use the `g:tagalong_filetypes` variable to change the list, add support for more filetypes, or only keep the ones you use. (Consider opening an issue to suggest changes to the default list.) See the "Settings" section for details.

## Requirements

The plugin requires the built-in "matchit" plugin, but it takes care to load it, if it isn't already. If, for some reason, it can't be loaded, this plugin will silently not work, to avoid problems with minimal installations. You can learn more about matchit by executing `:help matchit`.

## Features and Limitations

Not every method of changing the tag can be intercepted, or it might be too complicated or too invasive to do so. Here's the methods that work with the plugin:

- `c`: Anything involving a `c` operation, including `cw`, `ci<`, `cE`, or `C`.
- `v` + `c`: Selecting anything in visual mode and changing it with a `c`.
- `i`, `a`: Entering insert mode and making direct changes.

For all of these, the cursor needs to be within the `<>` angle brackets of the tag. If you change it from the outside, like with a `C` starting at the opening angle bracket, the plugin won't be activated.

A few examples of making a change that **WON'T** trigger the plugin:

- Using the `:substitute` command, for instance `:%s/<div /<span /g`.
- Yanking some text and pasting it over.
- Using the `r` or `x` mappings to change/delete one character.

Some of these might be implemented at a later time, but others might be too difficult or too invasive. If you often use a method that doesn't trigger the plugin, consider opening a github issue to discuss it.

Also note that the plugin relies on the `InsertLeave` autocommand to detect when to apply the change. If you exit insert mode via `<c-c>`, that won't be triggered. This is a good way to avoid the automatic behaviour, but if you commonly exit insert mode this way, it can be a problem. See the "Internals and Advanced Usage" section for help.

You can disable the plugin for particular mappings by overriding the `g:tagalong_mappings` variable. See the "Settings" section for details.

If you have [vim-repeat](https://github.com/tpope/vim-repeat) installed, you can repeat the last tag change with the `.` operator.

## Internals and Advanced Usage

The plugin installs its mappings with the function `tagalong#Init()`. All mappings and variables initialized are buffer-local. Instead of using `g:tagalong_filetypes`, you can actually just put `tagalong#Init()` in `~/.vim/ftplugin/<your-filetype>.vim`, and it should work. Or you can come up with some other criteria to activate it.

All the mappings (currently) do the following:

- Call the `tagalong#Trigger()` function. It stores information about the tag under the cursor in a buffer-local variable.
- Execute the original mapping.
- Upon exiting insert mode (see [`:help InsertLeave`](http://vimhelp.appspot.com/autocmd.txt.html#InsertLeave)), the function `tagalong#Apply()` gets called, takes the stored tag information and gets the changed tag and applies the change to both opening and closing tag
- The `tagalong#Reapply()` function can be invoked by vim-repeat, or it can be invoked manually, to perform the previous tag change.

So, if you wanted to make pasting over a tag activate the plugin, it might work like this:

``` vim
" The `<c-u>` removes the current visual mode, so a function can be called
xnoremap <buffer> p :<c-u>call <SID>Paste()<cr>

" The <SID> above is the same as the s: here
function! s:Paste()
  call tagalong#Trigger()

  " gv reselects the previously-selected area, and then we just paste
  normal! gvp

  call tagalong#Apply()
endfunction
```

This is not a built-in, because it feels a bit invasive, and there's other plugins (and snippets) that override `p`. Plus, repeating the operation doesn't seem to quite work. But I hope it's a good example to illustrate how you could try to build something more complicated with the core functions of the plugin.

If you commonly exit insert mode via `<c-c>`, the plugin won't be triggered, but you can take care of that with a mapping, if you'd like:

``` vim
inoremap <silent> <c-c> <c-c>:call tagalong#Apply()<cr>
```

It's generally not recommended -- `<c-c>` doesn't trigger |InsertLeave| semi-intentionally, I think, as an "escape hatch". But it depends on how you use it.

## Settings

TODO

## Alternatives

[vim-surround](https://github.com/tpope/vim-surround) gives you an interface to rename tags. It's explicit, rather than automatic, which I find inconvenient for this particular use case. It's older, though, so it likely works more reliably.

## Special Thanks

Thanks to [@BeatRichardz](https://twitter.com/BeatRichartz/status/1117621860055707648) for coming up with the plugin's name.

## Contributing

Pull requests are welcome, but take a look at [CONTRIBUTING.md](https://github.com/AndrewRadev/tagalong.vim/blob/master/CONTRIBUTING.md) first for some guidelines. Be sure to abide by the [CODE_OF_CONDUCT.md](https://github.com/AndrewRadev/tagalong.vim/blob/master/CODE_OF_CONDUCT.md) as well.
