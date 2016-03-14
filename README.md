vim-redpen
==========

This is a Vim integration of [redpen](https://github.com/redpen-cc/redpen) for proof reading.  [redpen](https://github.com/redpen-cc/redpen) is available for Markdown, AsciiDoc, Textile and LaTeX.

**Under construction**

### Usage

```
:Redpen [--quickrun] [redpen arguments...]
```

When you put a `redpen-config.xml` configuration file in a repository, vim-redpen detects it automatically. You can also set `g:redpen_default_config_path`.

### TODO

- [x] Configuration detection
- Engines
  - [x] [vim-quickrun](https://github.com/thinca/vim-quickrun)
  - [ ] [unite.vim](https://github.com/Shougo/unite.vim)
  - [ ] Inline (finally this should be default)
- [ ] Support Neovim job control
- [ ] Support Vim job control
- [ ] Help
- [ ] Tests

### FAQ

- **Why don't you extend [vim-grammarous](https://github.com/rhysd/vim-grammarous)?**

[vim-grammarous](https://github.com/rhysd/vim-grammarous) has too specific user experience for [languagetool](https://github.com/languagetool-org/languagetool).  [languagetool](https://github.com/languagetool-org/languagetool) is a very powerful grammar checker.  But it is not for proof reading.  In addition, redpen offers markdown support and provides more powerful Japanese checker.

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

