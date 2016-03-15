
highlight default link RedpenPreviewError ErrorMsg
highlight default link RedpenPreviewSection Keyword
highlight default link RedpenError SpellBad
augroup pluging-redpen-highlight
    autocmd!
    autocmd ColorScheme * highlight default link RedpenPreviewError ErrorMsg
    autocmd ColorScheme * highlight default link RedpenPreviewSection Keyword
    autocmd ColorScheme * highlight default link RedpenError SpellBad
augroup END

function! redpen#vital(module) abort
    if !exists('s:vital_cache')
        let s:vital_cache = {'V' : vital#of('redpen')}
    endif
    if !has_key(s:vital_cache, a:module)
        let s:vital_cache[a:module] = s:vital_cache.V.import(a:module)
    endif
    return s:vital_cache[a:module]
endfunction

function redpen#echo_error(msg, ...)
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

let s:ENGINES = ['--quickrun', '--unite', '--inline']

" Note: This invalidates a:args
function! s:parse_engine(args) abort
    let found = ''
    for idx in range(len(a:args))
        let arg = a:args[idx]
        if index(s:ENGINES, arg) >= 0
            if found !=# ''
                call redpen#echo_error('Only one engine can be specified: %s v.s. %s', found, arg)
                return ['', a:args]
            else
                let found = arg[2 : ]
                unlet a:args[idx]
            endif
        endif
    endfor
    return [found, a:args]
endfunction

function! redpen#open_error_preview(err, bufnr, already_open) abort
    if !a:already_open
        noautocmd silent execute 'pedit! __REDPEN_ERROR__'
    endif
    let unite_winnr = winnr()
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
        execute 1
        normal! "_dG
        silent put! =buffer

        syntax match RedpenPreviewSection "\%(Sentence\|Validator\):"
        syntax match RedpenPreviewError "Error:"

        setlocal nonumber
        setlocal nolist
        setlocal noswapfile
        setlocal nospell
        setlocal nomodeline
        setlocal nofoldenable
        setlocal foldcolumn=0
        setlocal nomodified

        let nr = bufwinnr(a:bufnr)
        echom nr
        if nr != -1
            execute nr . 'wincmd w'
            if has_key(a:err, 'startPosition')
                call cursor(a:err.startPosition.lineNum, a:err.startPosition.offset)
            else
                call cursor(a:err.lineNum, a:err.sentenceStartColumnNum)
            endif
        endif

        let b:redpen_bufnr = a:bufnr
    finally
        execute unite_winnr . 'wincmd w'
    endtry
endfunction

function! redpen#execute(conf, args) abort
    let opts = join(a:args, ' ') . ' 2>/dev/null'
    if a:conf !=# ''
        let opts = printf('-c %s %s', a:conf, opts)
    endif

    let cmd = g:redpen_command . ' ' . opts
    " XXX:
    " 'redpen' command always returns exit code 1...
    " XXX:
    " Vital.Process.system() causes an error on 2>/dev/null
    " Although '2>/dev/null' is added, there is stderr output at the last of
    " output.
    return system(cmd)
endfunction

function! redpen#json(conf, args) abort
    let output = redpen#execute(a:conf, a:args + ['-r', 'json'])
    try
        return redpen#vital('Web.JSON').decode(output)
    catch
        return []
    endtry
endfunction

function! s:region_includes(pos, start, end) abort
    return 0
endfunction

function! redpen#get_error_at(pos) abort
    if !exists('b:redpen_errors') || !has_key(b:redpen_errors, 'errors')
        return {}
    endif

    for e in b:redpen_errors.errors
        let l = a:pos[0]
        let c = a:pos[1]
        if has_key(e, 'startPosition') && has_key(e, 'endPosition')
            if l < e.startPosition.lineNum || e.endPosition.lineNum < l
                continue
            endif
            if l == e.startPosition.lineNum && c < e.startPosition.offset
                continue
            endif
            if l == e.endPosition.lineNum && e.endPosition.offset < c
                continue
            endif
            return e
        else
            let start_byte = line2byte(e.lineNum) + e.sentenceStartColumnNum + 2
            let end_byte = start_byte + strlen(e.sentence) - 1
            let pos_byte = line2byte(l) + c
            if start_byte <= pos_byte && pos_byte <= end_byte
                return e
            endif
        endif
    endfor
    return {}
endfunction

function! redpen#open_error_at(pos, short) abort
    let err = redpen#get_error_at(a:pos)
    if err == {}
        echo 'redpen: No error found under the cursor'
        return
    endif

    if a:short
        echomsg printf('%s [%s]', err.message, err.validator)
    else
        call redpen#open_error_preview(err, bufnr('%'), 0)
    endif
endfunction

function! redpen#reset_current_buffer() abort
    if !exists('b:redpen_errors')
        return
    endif

    if !has_key(b:redpen_errors, 'errors') || !has_key(b:redpen_errors, '__inline_highlights')
        unlet! b:redpen_errors
        return
    endif

    for e in b:redpen_errors.errors
        call matchdelete(e.__match_id)
    endfor
    unlet! b:redpen_errors
endfunction

function! redpen#set_current_buffer(conf, args) abort
    call redpen#reset_current_buffer()
    let json = redpen#json(a:conf, a:args)
    if json != []
        let b:redpen_errors = json[0]
    else
        let b:redpen_errors = {}
    endif
endfunction

function! s:calc_region_length(start, end) abort
    let line = a:start.lineNum
    if a:end.lineNum == line
        return a:end.offset - a:start.offset + 1
    endif

    let len = strlen(getline(line)) - a:start.offset + 1
    let line += 1
    while line != a:end.lineNum
        let += strlen(getline(line))
        let line += 1
    endwhile

    let len += a:end.offset
    return len
endfunction

function! s:matcherrpos(...) abort
    return matchaddpos('RedpenError', [a:000], 999)
endfunction

function! redpen#run_inline(conf, args) abort
    call redpen#set_current_buffer(a:conf, a:args)
    try
        for e in get(b:redpen_errors, 'errors', [])
            if has_key(e, 'startPosition') && has_key(e, 'endPosition')
                let length = s:calc_region_length(e.startPosition, e.endPosition)
                let e.__match_id = s:matcherrpos(e.startPosition.lineNum, e.startPosition.offset, length)
            else
                let e.__match_id = s:matcherrpos(e.lineNum, e.sentenceStartColumnNum + 2, strlen(e.sentence))
            endif
        endfor
    finally
        let b:redpen_errors.__inline_highlights = 1
    endtry
endfunction

function! redpen#run_unite(conf, args) abort
    call redpen#set_current_buffer(a:conf, a:args)
    call unite#start(['redpen'], {'auto_preview' : 1, 'start_insert' : 0})
endfunction

function! redpen#detect_config(file) abort
    let dir = fnamemodify(a:file, ':p:h')
    if !isdirectory(dir)
        return g:redpen_default_config_path
    endif

    let conf = findfile('redpen-config.xml', dir . ';')
    if conf ==# ''
        return g:redpen_default_config_path
    endif

    return conf
endfunction

function! redpen#run_quickrun(conf, args) abort
    let config = get(g:quickrun_config, 'redpen', {})

    let config.exec = '%c %o ' . join(a:args, ' ')
    if a:conf !=# ''
        let config.exec .= ' -c ' . a:conf
    endif
    let config.exec .= ' 2>/dev/null'
    let config.command = get(config, 'command', g:redpen_command)

    call quickrun#run(config)
    return 0
endfunction

function! redpen#run(args) abort
    if !executable(g:redpen_command)
        call redpen#echo_error("'%s' command is not found", g:redpen_command)
        return 1
    endif

    let [engine, args] = s:parse_engine(a:args)
    if engine ==# ''
        let engine = g:redpen_default_engine
    endif

    let file = ''
    if args == []
        let file = expand('%')
        if &modified || !filereadable(file)
            call redpen#echo_error('Current buffer is not saved: %s', file)
            return 1
        endif
        let args += [file]
    else
        for a in args
            if filereadable(a)
                let file = a
                break
            endif
        endfor
        if file ==# ''
            call redpen#echo_error('No existing file is included: %s', join(args, ' '))
            return 1
        endif
    endif

    return redpen#run_{engine}(redpen#detect_config(file), args)
endfunction

function! redpen#complete(arglead, cmdline, pos) abort
    return join(filter(map(glob(a:arglead . '*', 0, 1), 'isdirectory(v:val) ? v:val . "/" : v:val'), 'v:val =~# "\\.\\%(md\\|markdown\\|asciidoc\\|tex\\)\\|/$"'), "\n")
endfunction
