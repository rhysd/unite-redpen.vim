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

let s:ENGINES = ['--quickrun']

" Note: This invalidates a:args
function! s:parse_engine(args) abort
    let found = ''
    for idx in range(len(a:args))
        let arg = a:args[idx]
        if stridx(arg, '--') == 0 && index(s:ENGINES, arg) >= 0
            if found !=# ''
                call redpen#echo_error('Only one engine can be specified: %s v.s. %s', found, arg)
                return ['', a:args]
            else
                let found = arg
                unlet a:args[idx]
            endif
        endif
    endfor
    return [found, a:args]
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
