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

let g:unite_redpen_default_jumplist_preview = get(g:, 'unite_redpen_default_jumplist_preview', 0)

function! s:source.hooks.on_init(args, context) abort
    if exists('b:unite') && has_key(b:unite, 'prev_bufnr')
        let a:context.source__bufnr = b:unite.prev_bufnr
    else
        let a:context.source__bufnr = bufnr('%')
    endif

    let result = getbufvar(a:context.source__bufnr, 'redpen_errors')
    if type(result) == type('')
        let should_jump = a:context.source__bufnr != bufnr('%')
        if should_jump
            let w = bufwinnr(a:context.source__bufnr)
            execute w . 'wincmd w'
        endif
        let file = expand('%:p')
        let args = a:args != [] ? a:args : [file]
        call redpen#set_current_buffer(redpen#detect_config(file), args)
        if should_jump
            wincmd p
        endif
    endif
endfunction

function! s:source.hooks.on_syntax(args, context) abort
    syntax region uniteSource__RedpenString start=+"+ end=+"+ oneline contained containedin=uniteSource__Redpen
    syntax match uniteSource__RedpenLabel "\[\w\+]" contained containedin=uniteSource__Redpen
    highlight default link uniteSource__RedpenString String
    highlight default link uniteSource__RedpenLabel Comment
endfunction

function! s:source.gather_candidates(args, context) abort
    return map(copy(get(getbufvar(a:context.source__bufnr, 'redpen_errors'), 'errors', [])), '{
            \   "word" :  v:val.message . " [" . v:val.validator . "]",
            \   "action__buffer_nr" : a:context.source__bufnr,
            \   "action__line" : has_key(v:val, "startPosition") ? v:val.startPosition.lineNum : v:val.lineNum,
            \   "action__col" : has_key(v:val, "startPosition") ? v:val.startPosition.offset : v:val.sentenceStartColumnNum,
            \   "action__redpen_error" : v:val,
            \   "is_multiline" : 1,
            \ }')
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

if g:unite_redpen_default_jumplist_preview
    finish
endif

let s:source.action_table.preview = {
            \   'description' : 'Preview detail of the error',
            \   'is_quit' : 0,
            \ }
function! s:source.action_table.preview.func(candidate) abort
    if get(g:, 'unite_kind_file_vertical_preview', 0)
        let unite_winwidth = winwidth(0)
        noautocmd silent execute 'vertical pedit! __REDPEN_ERROR__'
        wincmd P
        let winwidth = (unite_winwidth + winwidth(0)) / 2
        execute 'wincmd p | vert resize ' . winwidth
    else
        noautocmd silent execute 'pedit! __REDPEN_ERROR__'
    endif
    call redpen#open_error_preview(a:candidate.action__redpen_error, a:candidate.action__buffer_nr, 1)
endfunction
