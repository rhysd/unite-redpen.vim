" unite.vim source definition {{{
let s:source = {
            \ 'name' : 'redpen',
            \ 'description' : 'Show result of redpen',
            \ 'default_kind' : 'jump_list',
            \ 'default_action' : 'open',
            \ 'hooks' : {},
            \ 'action_table' : {},
            \ 'syntax' : 'uniteSource__Redpen',
            \ }

function! unite#sources#redpen#define() abort
    return s:source
endfunction
" }}}

" Highlights {{{
highlight default link RedpenPreviewError ErrorMsg
highlight default link RedpenPreviewSection Keyword
highlight default link RedpenError SpellBad
augroup pluging-unite-redpen-highlight
    autocmd!
    autocmd ColorScheme * highlight default link RedpenPreviewError ErrorMsg
    autocmd ColorScheme * highlight default link RedpenPreviewSection Keyword
    autocmd ColorScheme * highlight default link RedpenError SpellBad
augroup END
" }}}

" Variables {{{
let s:V = vital#of('unite_redpen')
let s:JSON = s:V.import('Web.JSON')
let s:XML = s:V.import('Web.XML')
let s:EXT_MAP = {'markdown' : '.md', 'asciidoc' : '.asc', 'latex' : '.tex'}
let s:DICT_TYPE = type({})

let g:unite_redpen_default_jumplist_preview = get(g:, 'unite_redpen_default_jumplist_preview', 0)
let g:unite_redpen_default_config_path = get(g:, 'unite_redpen_default_config_path', '')
let g:unite_redpen_command = get(g:, 'unite_redpen_command', 'redpen')
let g:unite_redpen_detail_window_on_preview = get(g:, 'unite_redpen_detail_window_on_preview', 0)
let g:unite_redpen_default_mappings = get(g:, 'unite_redpen_default_mappings', 1)
" }}}

" Utilities {{{
function! s:echo_error(msg, ...) abort
    echohl ErrorMsg
    try
        if a:0 ==# 0
            echomsg a:msg
        else
            echomsg call('printf', [a:msg] + a:000)
        endif
    finally
        echohl None
    endtry
endfunction

function! unite#sources#redpen#detect_config(file) abort
    let dir = fnamemodify(a:file, ':p:h')

    let default = ''
    if g:unite_redpen_default_config_path !=# ''
        \ && filereadable(g:unite_redpen_default_config_path)
        let default = g:unite_redpen_default_config_path
    endif

    if !isdirectory(dir)
        return default
    endif

    let conf = findfile('redpen-config.xml', dir . ';')
    if conf ==# ''
        return default
    endif

    return conf
endfunction

function! s:generate_temporary_file() abort
    let name = tempname()
    if has_key(s:EXT_MAP, &filetype)
        let name .= s:EXT_MAP[&filetype]
    endif
    let lines = getline(1, '$')
    let failed = writefile(lines, name) != -1
    if failed
        call s:echo_error('Failed to create temporary file: %s', name)
        return ''
    endif
    return name
endfunction

function! unite#sources#redpen#run_command(args) abort
    if !executable(g:unite_redpen_command)
        call s:echo_error("'%s' command is not found", g:unite_redpen_command)
        return {}
    endif

    let args = a:args

    let file = ''
    if args == []
        let file = expand('%:p')
        if &modified || !filereadable(file)
            let file = s:generate_temporary_file()
            if file ==# ''
                return {}
            endif
            let temporary_file_created = 1
        endif
        let args += [file]
        let conf = unite#sources#redpen#detect_config(expand('%:p'))
    else
        for a in args
            if filereadable(a)
                let file = a
                break
            endif
        endfor
        if file ==# ''
            call s:echo_error('No existing file is included: %s', join(args, ' '))
            return {}
        endif
        let conf = unite#sources#redpen#detect_config(file)
    endif

    let args += ['-r', 'json']
    let opts = join(args, ' ') . ' 2>/dev/null'
    if conf !=# ''
        let opts = printf('-c %s %s', conf, opts)
    endif

    let cmd = g:unite_redpen_command . ' ' . opts
    " XXX:
    " 'redpen' command always returns exit code 1...
    " XXX:
    " Vital.Process.system() causes an error on 2>/dev/null
    " Although '2>/dev/null' is added, there is stderr output at the last of
    " output.
    let json = system(cmd)
    try
        let result = s:JSON.decode(json)[0]
        let result.__configuration = conf
        return result
    catch
        return {}
    finally
        if exists('l:temporary_file_created')
            call delete(file)
        endif
    endtry
endfunction
" }}}

" Error preview {{{
function! s:delete_current_error_match() abort
    if exists('b:unite_redpen_error_match_id')
        call matchdelete(b:unite_redpen_error_match_id)
        unlet! b:unite_redpen_error_match_id
    endif
endfunction

function! s:matcherrpos(...) abort
    return matchaddpos('RedpenError', [a:000], 999)
endfunction

function! s:matcherr(start, end) abort
    let line = a:start.lineNum
    if a:end.lineNum == line
        return s:matcherrpos(a:start.lineNum, a:start.offset+1, a:end.offset - a:start.offset + 1)
    endif

    let len = strlen(getline(line)) - a:start.offset + 1
    let line += 1
    while line != a:end.lineNum
        let len += strlen(getline(line))
        let line += 1
    endwhile

    let len += a:end.offset
    return s:matcherrpos(a:start.lineNum, a:start.offset+1, len)
endfunction

function! s:move_to_error(err, bufnr) abort
    let nr = bufwinnr(a:bufnr)
    if nr < 0
        return
    endif

    try
        if nr != -1
            execute nr . 'wincmd w'
            call s:delete_current_error_match()

            if has_key(a:err, 'startPosition')
                let l = a:err.startPosition.lineNum
                let c = a:err.startPosition.offset
                call cursor(a:err.startPosition.lineNum, a:err.startPosition.offset)
                let b:unite_redpen_error_match_id = s:matcherr(a:err.startPosition, a:err.endPosition)
            else
                call cursor(a:err.lineNum, a:err.sentenceStartColumnNum)
            endif
        endif
    finally
        wincmd p
    endtry
endfunction

function! s:write_error_preview(err, bufnr) abort
    let prev_winnr = winnr()
    try
        wincmd P
        let buffer = join([
                \   'Error:',
                \   '  ' . a:err.message,
                \   '',
                \   'Sentence:',
                \   '  ' . matchstr(a:err.sentence, '^\s*\zs.*'),
                \   '',
                \   'Validator:',
                \   '  ' . a:err.validator,
                \ ], "\n")
        normal! gg"_dG
        silent put! =buffer

        syntax match RedpenPreviewSection "\%(Sentence\|Validator\):"
        syntax match RedpenPreviewError "Error:"

        execute 'resize' line('$')
        execute 1

        setlocal nonumber
        setlocal nolist
        setlocal noswapfile
        setlocal nospell
        setlocal nomodeline
        setlocal nofoldenable
        setlocal foldcolumn=0
        setlocal nomodified
        setlocal bufhidden=delete
        setlocal buftype=nofile
    finally
        execute prev_winnr . 'wincmd w'
    endtry
endfunction

function! s:open_detail_window(err, bufnr) abort
    if get(g:, 'unite_kind_file_vertical_preview', 0)
        let unite_winwidth = winwidth(0)
        noautocmd silent execute 'vertical pedit! __REDPEN_ERROR__'
        wincmd P
        let winwidth = (unite_winwidth + winwidth(0)) / 2
        execute 'wincmd p | vert resize ' . winwidth
    else
        noautocmd silent execute 'pedit! __REDPEN_ERROR__'
    endif
    call s:write_error_preview(a:err, a:bufnr)
endfunction
" }}}

" Source implementation {{{
" Hooks {{{
function! s:source.hooks.on_init(args, context) abort
    if exists('b:unite') && has_key(b:unite, 'prev_bufnr')
        let a:context.source__bufnr = b:unite.prev_bufnr
    else
        let a:context.source__bufnr = bufnr('%')
    endif

    let should_jump = a:context.source__bufnr != bufnr('%')
    if should_jump
        let w = bufwinnr(a:context.source__bufnr)
        execute w . 'wincmd w'
    endif

    let file = expand('%:p')
    let args = a:args != [] ? a:args : [file]
    let a:context.source__redpen_errors = unite#sources#redpen#run_command(args)

    if should_jump
        wincmd p
    endif
endfunction

function! s:source.hooks.on_syntax(args, context) abort
    syntax region uniteSource__RedpenString start=+"+ end=+"+ oneline contained containedin=uniteSource__Redpen
    syntax match uniteSource__RedpenLabel "\[\w\+]" contained containedin=uniteSource__Redpen
    highlight default link uniteSource__RedpenString String
    highlight default link uniteSource__RedpenLabel Comment

    if g:unite_redpen_default_mappings
        nnoremap <buffer><silent><expr>d unite#smart_map('d', unite#do_action('detail'))
        nnoremap <buffer><silent><expr>a unite#smart_map('a', unite#do_action('add_to_whitelist'))
    endif
endfunction

function! s:source.hooks.on_close(args, context) abort
    let winnr = winbufnr(a:context.source__bufnr)
    if winnr < 0
        return
    endif

    try
        execute winnr . 'wincmd w'
        call s:delete_current_error_match()
    finally
        wincmd p
    endtry
endfunction

function! s:source.gather_candidates(args, context) abort
    if a:context.source__redpen_errors == {}
        return []
    endif

    let errors = get(a:context.source__redpen_errors, 'errors', [])
    let ret = []
    for idx in range(len(errors))
        let e = errors[idx]
        let e.__configuration = a:context.source__redpen_errors.__configuration
        let ret += [{
            \   'word' :  e.message . ' [' . e.validator . ']',
            \   'is_multiline' : 1,
            \   'action__buffer_nr' : a:context.source__bufnr,
            \   'action__line' : has_key(e, 'startPosition') ? e.startPosition.lineNum : e.lineNum,
            \   'action__col' : (has_key(e, 'startPosition') ? e.startPosition.offset : e.sentenceStartColumnNum) + 1,
            \   'action__redpen_error' : e,
            \   'action__redpen_id' : idx,
            \ }]
    endfor

    return ret
endfunction
" }}}

" Actions {{{
let s:source.action_table.echo_json = {
            \   'description' : 'Echo JSON value corresponding to the error',
            \ }
function! s:source.action_table.echo_json.func(candidate) abort
    try
        PrettyPrint a:candidate.action__redpen_error
    catch
        echo a:candidate.action__redpen_error
    endtry
endfunction

let s:source.action_table.detail = {
            \   'description' : 'Show detail of the error',
            \   'is_quit' : 0
            \ }
function! s:source.action_table.detail.func(candidate) abort
    let id = a:candidate.action__redpen_id
    if exists('b:unite_redpen_detail_opened') && (id == b:unite_redpen_detail_opened)
        pclose
        unlet! b:unite_redpen_detail_opened
    else
        call s:open_detail_window(a:candidate.action__redpen_error, a:candidate.action__buffer_nr)
        let b:unite_redpen_detail_opened = id
    endif
endfunction

function! s:find_property(validator) abort
    let object_type = type({})
    for c in a:validator.child
        if type(c) == s:DICT_TYPE && has_key(c, 'name') && c.name ==# 'property'
            return c
        endif
        unlet c
    endfor
    return {}
endfunction

function! s:find_spelling_validator(xml) abort
    let vs = a:xml.find('validators')
    if vs ==# {}
        return [{}, {}, -1]
    endif

    for idx in range(len(vs.child))
        let node = vs.child[idx]
        if type(node) != s:DICT_TYPE
            unlet l:node
            continue
        endif
        if has_key(node.attr, 'name') && node.attr.name ==# 'Spelling'
            return [vs, node, idx]
        endif
        unlet l:node
    endfor

    return [vs, {}, -1]
endfunction

function! s:update_misspelling_whitelist(xml, word) abort
    let [validators, validator, index] = s:find_spelling_validator(a:xml)
    if index == -1
        call s:echo_error('<Spelling/> validator was not found')
        return {}
    endif

    let prop = s:find_property(validator)
    if !has_key(prop, 'attr') || !has_key(prop.attr, 'value')
        let indent = index > 0 ? validators.child[index-1] : "\n"
        let child = s:XML.createElement('property')
        let child.attr = {
                \   'name' : 'list',
                \   'value' : a:word,
                \ }
        let validator.child = [indent . '  ', child, indent]
        return a:xml
    else
        let prop.attr.value .= ',' . a:word
        return a:xml
    endif
endfunction

let s:source.action_table.add_to_whitelist = {
            \   'description' : 'Add the misspelling word to whitelist',
            \   'is_quit' : 0,
            \ }
function! s:source.action_table.add_to_whitelist.func(candidate) abort
    let word = matchstr(a:candidate.word, 'ミススペルの可能性がある単語 "\zs[^"]\+\ze" がみつかりました。')
    if word ==# ''
        call s:echo_error('No word was found from the error message')
        return
    endif

    let conf = a:candidate.action__redpen_error.__configuration
    if conf ==# ''
        call s:echo_error('No configuration file was detected to add symbol')
        return
    endif
    let xml = s:XML.parseFile(conf)
    let xml = s:update_misspelling_whitelist(xml, word)
    if xml == {}
        return
    endif

    call writefile(split(xml.toString(), "\n"), conf)
    echom 'Added "' . word . '" to whitelist of misspelling validator.'
endfunction

if g:unite_redpen_default_jumplist_preview
    finish
endif

let s:source.action_table.preview = {
            \   'description' : 'Preview detail of the error',
            \   'is_quit' : 0,
            \ }
function! s:source.action_table.preview.func(candidate) abort
    let e = a:candidate.action__redpen_error
    let b = a:candidate.action__buffer_nr

    if g:unite_redpen_detail_window_on_preview
        call s:open_detail_window(e, b)
    endif

    call s:move_to_error(e, b)
endfunction
" }}}
" }}}
