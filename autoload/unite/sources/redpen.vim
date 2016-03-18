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
let s:J = s:V.import('Web.JSON')
let s:EXT_MAP = {'markdown' : '.md', 'asciidoc' : '.asc', 'latex' : '.tex'}

let g:unite_redpen_default_jumplist_preview = get(g:, 'unite_redpen_default_jumplist_preview', 0)
let g:unite_redpen_default_config_path = get(g:, 'unite_redpen_default_config_path', '')
let g:unite_redpen_command = get(g:, 'unite_redpen_command', 'redpen')
let g:unite_redpen_detail_window_on_preview = get(g:, 'unite_redpen_detail_window_on_preview', 0)
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
    if !isdirectory(dir)
        return g:unite_redpen_default_config_path
    endif

    let conf = findfile('redpen-config.xml', dir . ';')
    if conf ==# ''
        return g:unite_redpen_default_config_path
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
        return s:J.decode(json)[0]
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

    nnoremap <buffer><silent><expr>d unite#smart_map('d', unite#do_action('detail'))
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

let s:source.action_table.echo_json = {
            \   'description' : 'Echo JSON value corresponding to the error',
            \ }
function! s:source.action_table.echo_json.func(candidate) abort
    try
        PP a:candidate.action__redpen_error
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
