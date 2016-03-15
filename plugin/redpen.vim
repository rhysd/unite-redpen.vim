if (exists('g:loaded_redpen') && g:loaded_redpen) || &cp
    finish
endif

let g:redpen_command = get(g:, 'redpen_command', 'redpen')
let g:redpen_default_engine = get(g:, 'redpen_default_engine', 'unite')
let g:redpen_default_config_path = get(g:, 'redpen_default_config_path', '')
let g:redpen_unite_default_context = get(g:, 'redpen_unite_default_context', {'auto_preview' : 1, 'start_insert' : 0})

command! -nargs=* -complete=custom,redpen#complete Redpen call redpen#run([<f-args>])
command! -nargs=0 RedpenReset call redpen#reset_current_buffer()

nnoremap <silent><Plug>(redpen-open-error) :<C-u>call redpen#open_error_at(getpos('.')[1:2], 0)<CR>
nnoremap <silent><Plug>(redpen-echo-error) :<C-u>call redpen#open_error_at(getpos('.')[1:2], 1)<CR>
nmap ge <Plug>(redpen-echo-error)

let g:loaded_redpen = 1
