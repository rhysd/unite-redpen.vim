if (exists('g:loaded_redpen') && g:loaded_redpen) || &cp
    finish
endif

let g:redpen_command = get(g:, 'redpen_command', 'redpen')
let g:redpen_default_engine = get(g:, 'redpen_default_engine', 'quickrun')
let g:redpen_default_config_path = get(g:, 'redpen_default_config_path', '')

command! -nargs=* Redpen call redpen#run([<f-args>])

let g:loaded_redpen = 1
