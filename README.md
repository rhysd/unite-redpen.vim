unite-redpen.vim
================

This is a [unite.vim](https://github.com/Shougo/unite.vim) integration of [redpen](https://github.com/redpen-cc/redpen) for proof reading.  You can validate double-negative, weak-expression, doubled-word, [and so on](http://redpen.cc/docs/latest/index.html#validator).  [redpen](https://github.com/redpen-cc/redpen) is available for Markdown, AsciiDoc, Textile and LaTeX.

### Usage

TODO: screenshot

```vim
:Unite redpen

" With command line options
:Unite redpen:--limit:10

" Show preview automatically
:Unite redpen -auto-preview
```

The command executes `redpen` and show the errors reported by it in unite.vim window.  In the list, you can preview detail of the error (`p` is assigned by default).  When select an item in the list, cursor will move to the error position.  If you want to use previous, you can use `:UniteResume` command to restore last unite.vim window.

If you put a `redpen-config.xml` configuration file in a repository, unite-redpen.vim detects it automatically. You can also set `g:redpen_default_config_path` for global default configuration.


If you want to use [vim-quickrun](https://github.com/thinca/vim-quickrun) to execute redpen, you can use `unite#sources#redpen#detect_config()` function.

```vim
let conf = {'command': 'redpen'}
let redpen_conf = unite#sources#redpen#detect_config(expand('%:p'))
if redpen_conf !=# ''
    conf.cmdopt = '-c ' . redpen_conf . ' 2>/dev/null'
endif
call quickrun#run(conf)
```

### TODO

- [x] Fundamentals
- [x] Configuration detection
- [ ] Available on temprary/unsaved buffer
- [ ] Help
- [ ] Tests

### FAQ

- **Why don't you extend [vim-grammarous](https://github.com/rhysd/vim-grammarous)?**

[vim-grammarous](https://github.com/rhysd/vim-grammarous) has too specific user experience for [languagetool](https://github.com/languagetool-org/languagetool).  [languagetool](https://github.com/languagetool-org/languagetool) is a powerful grammar checker.  But it is not for proof reading.  In addition, redpen offers markdown support and provides more powerful Japanese checker.

### License

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

