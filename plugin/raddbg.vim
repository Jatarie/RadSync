" raddbg.vim - Simple Vim integration with raddbg via IPC
" Provides commands and mappings to toggle breakpoints and control raddbg.

if exists('g:loaded_raddbg_vim')
  finish
endif
let g:loaded_raddbg_vim = 1

" Initialize state and signs
silent! call raddbg#Init()

" User commands
command! -bar RadToggleBreakpoint call raddbg#ToggleBreakpoint()
command! -bar RadClear             call raddbg#Clear()
command! -bar RadStart             call raddbg#Start()
command! -bar RadStop              call raddbg#Stop()
command! -bar RadRestart           call raddbg#Restart()
command! -nargs=1 RadAddFunctionBreakpoint call raddbg#AddFunctionBreakpoint(<f-args>)
command! -bar RadStatus            call raddbg#Status()

" Default mappings (can be disabled by setting g:raddbg_map_keys = 0 before loading)
if get(g:, 'raddbg_map_keys', 1)
  nnoremap <silent> <leader>rb :RadClear<CR>:RadToggleBreakpoint<CR>
  nnoremap <silent> <leader>rs :RadStart<CR>
  nnoremap <silent> <leader>rS :RadStop<CR>
  nnoremap <silent> <leader>rr :RadRestart<CR>
  nnoremap <silent> <leader>rc :RadClear<CR>
  nnoremap <silent> <leader>rf :RadClear<CR>:RadAddFunctionBreakpoint 
endif
