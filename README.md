# raddbg.vim (RadSync)

Vim plugin to control [raddbg](https://github.com/RedBox13/raddbg) via its `--ipc` interface.

It mirrors the behavior of your N10X Python snippet:
- On adding a breakpoint: clears raddbg breakpoints, adds a function breakpoint for `WinMain`, then adds the file:line breakpoint.
- On removing a breakpoint: clears raddbg breakpoints.
- Provides run/stop/restart commands.

## Install (vim-plug)

Add to your vimrc (Windows paths shown):

```vim
" Use a local path for development
Plug 'local-raddbg', { 'dir': 'c:/Users/Matt/Desktop/RadSync' }
```

Then in Vim:

1. :PlugInstall
2. :helptags ALL  (optional, to enable :help raddbg)

> Alternatively, put this repo in a Git host and use: `Plug 'owner/repo'`.

## Usage

Commands:
- `:RadToggleBreakpoint`  Toggle a breakpoint at the current line
- `:RadClear`             Clear all breakpoints (signs + raddbg)
- `:RadStart`             raddbg --ipc run
- `:RadStop`              raddbg --ipc kill_all
- `:RadRestart`           raddbg --ipc restart
- `:RadAddFunctionBreakpoint <Name>`  Add a function breakpoint in raddbg
- `:RadStatus`            Show internal status

Default mappings (set `let g:raddbg_map_keys = 0` to disable):
- `<leader>rb`  Toggle breakpoint
- `<leader>rs`  Start (run)
- `<leader>rS`  Stop (kill_all)
- `<leader>rr`  Restart
- `<leader>rc`  Clear breakpoints

## Config

```vim
let g:raddbg_exe = 'raddbg'         " Path to raddbg (on PATH or absolute)
let g:raddbg_sign = '●'             " Sign text for breakpoints
let g:raddbg_sign_hl = 'WarningMsg' " Highlight group for sign
let g:raddbg_map_keys = 1           " 0 to disable default mappings
```

## Notes

- Requires Vim 8+ with +signs. `system(list)` is used to spawn raddbg.
- File paths are absolute when sending to raddbg.
- Non-zero exit status from raddbg is ignored (best-effort IPC).
