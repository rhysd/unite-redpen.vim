Tests are written with the Vim plugin testing framework, [vim-themis](https://github.com/thinca/vim-themis).

How to execute tests:

```sh
$ cd path/to/unite-redpen.vim
$ git clone https://github.com/thinca/vim-themis
$ git clone https://github.com/Shougo/unite.vim.git # if not installed yet
$ ./vim-themis/bin/themis test/
```

To use [guard](https://github.com/guard/guard), execute `guard` at the root of repository.

```sh
$ cd path/to/unite-redpen.vim
$ guard --guardfile test/Guardfile
```
