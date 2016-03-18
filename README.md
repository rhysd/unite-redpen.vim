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
- In the list, you can confirm place of the error with highlight (`p` is assigned by default).
- In the list, you can see the detail with mini window (`d` is assigned by default).  `d` toggles the mini window.
- If you want to use previous result, you can use `:UniteResume` command to restore last unite.vim window.
- If you put a `redpen-config.xml` configuration file in a repository, unite-redpen.vim detects it automatically.
- You can also set `g:redpen_default_config_path` for global default configuration.


## TODO

- [x] Fundamentals
- [x] Configuration detection
- [x] Available on temprary/unsaved buffer
- [x] Help
- [ ] Tests

## FAQ

### Why don't you extend [vim-grammarous](https://github.com/rhysd/vim-grammarous)?

[vim-grammarous](https://github.com/rhysd/vim-grammarous) has too specific user experience for [languagetool](https://github.com/languagetool-org/languagetool).  [languagetool](https://github.com/languagetool-org/languagetool) is a powerful grammar checker.  But it is not for proof reading.  In addition, redpen offers markdown support and provides more powerful Japanese checker.

### Can I run [vim-quickrun](https://github.com/thinca/vim-quickrun) instead of unite.vim?

You can use `unite#sources#redpen#detect_config()` and `quickrun#run()`.

```vim
function! s:run_redpen_with_quickrun(...) abort
    let file = get(a:, 1, expand('%:p'))
    let conf = {
        \   'command': 'redpen',
        \   'exec' : '%c %o %s 2>/dev/null',
        \   'srcfile' : file,
        \ }
    let redpen_conf = unite#sources#redpen#detect_config(file)
    if redpen_conf !=# ''
        let conf.cmdopt = '-c ' . redpen_conf
    endif
    call quickrun#run(conf)
endfunction

" `:Redpen` checks current file
" `:Redpen file` checks the file
command! -nargs=? Redpen call s:run_redpen_with_quickrun(<f-args>)
```


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

