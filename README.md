unite-redpen.vim
================
> [![Build Status](https://travis-ci.org/rhysd/unite-redpen.vim.svg?branch=master)](https://travis-ci.org/rhysd/unite-redpen.vim)

This is a [unite.vim](https://github.com/Shougo/unite.vim) integration of [redpen](https://github.com/redpen-cc/redpen) for proof reading.  You can validate double-negative, weak-expression, doubled-word, [and so on](http://redpen.cc/docs/latest/index.html#validator).  [redpen](https://github.com/redpen-cc/redpen) is available for Markdown, AsciiDoc, Textile and LaTeX.

## Usage

TODO: screenshot

```vim
:Unite redpen

" Show preview automatically
:Unite redpen -auto-preview

" With command line options
:Unite redpen:--limit:10
```

Features:

- `:Unite redpen` executes `redpen` and show list of the errors reported by it in unite.vim window.
- When select an item in the list, cursor will move to the error position.
- If you put a `redpen-config.xml` configuration file in a repository, unite-redpen.vim detects it automatically.
- In the list, you can confirm place of the error with highlight (`p` is assigned by default).
- In the list, you can see the detail with mini window (`d` is assigned by default).  `d` toggles the mini window.
- In the list, you can add the word to whitelist from misspelling error ("a" is assigned by default).
- If you want to use previous result, you can use `:UniteResume` command to restore last unite.vim window.
- You can also set `g:redpen_default_config_path` for global default configuration.

Please see [documentation](doc/unite-redpen.txt) to know all features.


## TODO

- [x] Fundamentals
- [x] Configuration detection
- [x] Available on temprary/unsaved buffer
- [x] Help
- [x] Add an action to add a symbol from misspelling error
- [ ] Tests


## License

Distributed under [MIT license](https://opensource.org/licenses/MIT).

    Copyright (c) 2016 rhysd

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
    PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
    THE USE OR OTHER DEALINGS IN THE SOFTWARE.

