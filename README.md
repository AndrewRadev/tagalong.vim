[![GitHub version](https://badge.fury.io/gh/andrewradev%2Ftagalong.vim.svg)](https://badge.fury.io/gh/andrewradev%2Ftagalong.vim)
[![Build Status](https://travis-ci.org/AndrewRadev/tagalong.vim.svg?branch=master)](https://travis-ci.org/AndrewRadev/tagalong.vim)

![Tagalong](http://i.andrewradev.com/52e379b8425f731b215811c024683949.png)

## Basic Usage

The plugin is designed to automatically rename closing HTML/XML tags when editing opening ones (or the other way around). For the most part, you should be able to edit your code normally (see below for limitations) and the plugin would take care of the renaming once you leave insert mode:

![Demo](http://i.andrewradev.com/f52337c3b41b6f2269407c1b332caf9c.gif)

Apart from HTML tags, it'll also detect XML-style `<namespaced:tags>`, react-style `<Component.Subcomponents>`, ember-style `<component/paths>`.

The plugin only activates for HTML-like buffers, or at least all the ones that I could think of. You can see the full list in the setting `g:tagalong_filetypes`. You can set that variable yourself to limit it to the ones you use. You can activate the plugin for more filetypes by changing `g:tagalong_additional_filetypes` (but consider opening an issue to suggest changes to the default list). See the "Settings" section for more details.

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
- Entering insert mode outside of the tag, navigating to it and changing it.

Some of these might be implemented at a later time, but others might be too difficult or too invasive. If you often use a method that doesn't trigger the plugin, consider opening a github issue to discuss it.

Also note that the plugin relies on the `InsertLeave` autocommand to detect when to apply the change. If you exit insert mode via `<c-c>`, that won't be triggered. This is a good way to avoid the automatic behaviour, but if you commonly exit insert mode this way, it can be a problem. See the "Internals and Advanced Usage" section for help.

You can disable the plugin for particular mappings by overriding the `g:tagalong_mappings` variable. See the "Settings" section for details.You can also disable it explicitly by calling the command `:TagalongDeinit`, and later re-enable it with `:TagalongInit`. This could be quite useful if you run into a bug and the buffer gets messed up!

Large files can also be a problem. With a 100,000-line XML file and tags that wrap its entirety, the plugin really takes time, even during normal editing within a tag. To avoid this, its operation has been limited to 500 milliseconds, configurable via the `g:tagalong_timeout` variable. This means, unfortunately, that in said large file, closing tags may not be reliably updated. This should be rare, hopefully.

With `g:tagalong_verbose` turned on, you'll get a message that the matching tag was NOT updated if the search for it times out. Alternatively, you can set `g:tagalong_timeout` to 0 for no timeout and, if you see a dramatic slowdown, use `<c-c>` and run `:TagalongDeinit` to disable the plugin in this buffer. You could implement an automated solution by checking the value of `line('$')`.

If you have [vim-repeat](https://github.com/tpope/vim-repeat) installed, you can repeat the last tag change with the `.` operator.

## Internals and Advanced Usage

The plugin installs its mappings with the function `tagalong#Init()`. All mappings and variables initialized are buffer-local. Instead of using `g:tagalong_filetypes`, you can actually just put `tagalong#Init()` in `~/.vim/ftplugin/<your-filetype>.vim`, and it should work. Or you can come up with some other criteria to activate it.

All the mappings (currently) do the following:

- Call the `tagalong#Trigger(<mapping>, <count>)` function. It stores information about the tag under the cursor in a buffer-local variable and executes the original mapping.
- Upon exiting insert mode (see [`:help InsertLeave`](http://vimhelp.appspot.com/autocmd.txt.html#InsertLeave)), the function `tagalong#Apply()` gets called, takes the stored tag information and gets the changed tag and applies the change to both opening and closing tag
- The `tagalong#Reapply()` function can be invoked by vim-repeat, or it can be invoked manually, to perform the previous tag change.

The initial function, `tagalong#Trigger`, can also be invoked with no arguments, which means it will only store tag information to prepare `tagalong#Apply()`. This allows you to do something more complicated between the two calls. For example, if you wanted to make pasting over a tag activate the plugin, it might work like this:

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

It's generally not recommended -- `<c-c>` doesn't trigger `InsertLeave` semi-intentionally, I think, as an "escape hatch". But it depends on how you use it.

## Settings

### `g:tagalong_filetypes`

Example usage:

``` vim
let g:tagalong_filetypes = ['html']
```

Default value:

```
['html', 'xml', 'jsx', 'eruby', 'ejs', 'eco', 'php', 'htmldjango', 'javascriptreact', 'typescriptreact']
```

This variable holds all of the filetypes that the plugin will install mappings for. If, for some reason, you'd like to avoid its behaviour for particular markup languages, you can set the variable to a list of the ones you'd like to keep.

To add more filetypes, check out `g:tagalong_additional_filetypes` below.

If you set it to an empty list, `[]`, the plugin will not be automatically installed for any filetypes, but you can activate it yourself by calling the `tagalong#Init()` function in a particular buffer.

### `g:tagalong_additional_filetypes`

Example usage:

``` vim
let g:tagalong_additional_filetypes = ['custom', 'another']
```

Default value: `[]`

The plugin should work with any HTML-like tags, so if a compatible filetype is missing in `g:tagalong_filetypes`, you can add it here. Or you can call the `tagalong#Init()` function in your buffer.

Ideally, the above setting would just hold all sensible filetypes, so consider opening a github issue to suggest one that you feel is missing. As long as it's not something too custom, I would likely be okay with adding it to the built-in list.

### `g:tagalong_excluded_filetype_combinations`

Example usage:

``` vim
let g:tagalong_excluded_filetype_combinations = ['custom.html']
```

Default value: `['eruby.yaml']`

This setting allows the exclusion of particular filetype dot-combinations from initialization. The "filetypes" setting includes single filetypes, so any combination of them including, for instance, "html" would activate the plugin. So you could set custom filetypes like "html.rails" or something and it would still work.

That said, there are combinations that are not HTML-like. The current default value of the setting, "eruby.yaml" is a good example -- it's being set by vim-rails, but there's no HTML to edit in there.

It's recommended to leave this setting untouched, but you could use it as an escape hatch. If you have any problems with a particular filetype that are solved by an entry in this setting, consider opening an issue to make a change to the defaults.

### `g:tagalong_mappings`

Example usage:

``` vim
let g:tagalong_mappings = [{'c': '_c'}, 'i', 'a']
```

Default value: `['c', 'C', 'v', 'i', 'a']`

This setting controls which types of editing will have mappings installed for them. Currently, these are literal mappings -- each character in the list is a mapping that you can see by executing `:nmap c`, for instance. But it's not necessary to be the case -- in the future, the values in the list might be labels of some sort that will be explained in more detail in the documentation.

Changing this variable means that editing the buffer with the removed mappings won't trigger the plugin. You could set it to `['i', 'a']` if you usually edit tags by entering insert mode and backspacing over the tag. That way, the `c` family of mappings could be remapped by some other plugin, for instance. Or you could use them to give yourself an escape hatch, if the plugin bugs out or you have good reason not to update the other tag.

Note that the plugin will attempt to respect your previous mappings of any of these keys. If you have an `nnoremap c` in your `.vimrc` file, it'll be applied. Mapping `cw`, on the other hand, will likely just use your mapping, instead of hitting the plugin at all. If you're having problems with this, please open a github issue.

If you want to use a special key sequence to replace a built-in, you can put a dictionary instead of a single letter in the setting. For instance, instead of `'c'`, you can put in `{'c': '_c'}`, and it would use the `_c` key sequence to act as the native `c` key with tagalong's effect. You can use that to avoid conflicts with other plugins overriding the native keys. It's generally not recommended -- the power of the plugin is that it works automatically, otherwise you could use vim-surround instead. But it's your call.

If you set it to an empty list, `[]`, the plugin will not be activated by any mappings, but you can read the "Internals and Advanced Usage" section for other ways of using it.

### `g:tagalong_verbose`

Example usage:

``` vim
let g:tagalong_verbose = 1
```

Default value: `0`

If you set this value to 1, the plugin will print out a message every time it auto-updates a closing/opening tag. Could be useful if you'd like to be sure the change was made, especially if it's offscreen.

## Alternatives

[vim-surround](https://github.com/tpope/vim-surround) gives you an interface to rename tags. It's explicit, rather than automatic, which I find inconvenient for this particular use case. It's older, though, so it likely works more reliably.

## Special Thanks

Thanks to [@BeatRichardz](https://twitter.com/BeatRichartz/status/1117621860055707648) for coming up with the plugin's name.

## Contributing

Pull requests are welcome, but take a look at [CONTRIBUTING.md](https://github.com/AndrewRadev/tagalong.vim/blob/master/CONTRIBUTING.md) first for some guidelines. Be sure to abide by the [CODE_OF_CONDUCT.md](https://github.com/AndrewRadev/tagalong.vim/blob/master/CODE_OF_CONDUCT.md) as well.
