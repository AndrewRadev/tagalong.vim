[![Build Status](https://travis-ci.org/AndrewRadev/tagalong.vim.svg?branch=master)](https://travis-ci.org/AndrewRadev/tagalong.vim)

![Tagalong](http://i.andrewradev.com/52e379b8425f731b215811c024683949.png)

## Basic Usage

The plugin is designed to automatically rename closing tags when editing opening ones (or the other way around). For the most part, you should be able to edit your code normally (see below for limitations) and the plugin would take care of the renaming once you leave insert mode:

![Demo](http://i.andrewradev.com/d31c94c2db184db8883726031deff69c.gif)

TODO: settings, activation instructions

## Requirements

The plugin requires the built-in "matchit" plugin, but it takes care to load it, if it isn't already. If, for some reason, it can't be loaded, this plugin will silently not work, to avoid problems with minimal installations. You can learn more about matchit by executing `:help matchit`.

TODO test on 7.4

## Limitations

Not every method of changing the tag can be intercepted, or it might be too complicated or too invasive to do so. Here's the methods that work with the plugin:

- `c`: Anything involving a `c` operation, including `cw`, `ci<`, `cE`, or `C`.
- `v` + `c`: Selecting anything in visual mode and changing it with a `c`.
- `i`, `a`: Entering insert mode and making direct changes.

A few examples of making a change that **WON'T** trigger the plugin:

- Using the `:substitute` command, for instance `:%s/<div /<span /g`.
- Yanking some text and pasting it over.
- Using the `r` or `x` mappings to change/delete one character.

Some of these might be implemented later, but others might be too difficult or too invasive. If you often use a method that doesn't trigger the plugin, consider opening a github issue to discuss it.

## Alternatives

[vim-surround](https://github.com/tpope/vim-surround) gives you an interface to rename tags. It's explicit, rather than automatic, which I find inconvenient for this particular use case. It's older, though, so it likely works more reliably.

## Special Thanks

Thanks to [@BeatRichardz](https://twitter.com/BeatRichartz/status/1117621860055707648) for coming up with the plugin's name.

## Contributing

Pull requests are welcome, but take a look at [CONTRIBUTING.md](https://github.com/AndrewRadev/tagalong.vim/blob/master/CONTRIBUTING.md) first for some guidelines.
