" autoload/raddbg.vim

let s:breakpoints = {}
let s:sign_id_next = 5000

function! raddbg#Init() abort
  if !exists('g:raddbg_sign')
    let g:raddbg_sign = '●'
  endif
  if !exists('g:raddbg_sign_hl')
    let g:raddbg_sign_hl = 'WarningMsg'
  endif
  if !exists('g:raddbg_exe')
    let g:raddbg_exe = 'raddbg'
  endif

  if has('signs')
    execute 'sign define raddbg_breakpoint text=' . shellescape(g:raddbg_sign) . ' texthl=' . g:raddbg_sign_hl
  endif
endfunction

function! s:bufkey(bufnr) abort
  return bufname(a:bufnr)
endfunction

function! s:cur_loc() abort
  return [bufnr('%'), line('.')]
endfunction

function! raddbg#ToggleBreakpoint() abort
  let [bnum, lnum] = s:cur_loc()
  call raddbg#AddOrRemoveBreakpoint(bnum, lnum)
endfunction

function! raddbg#AddOrRemoveBreakpoint(bnum, lnum) abort
  let key = s:bufkey(a:bnum) . ':' . a:lnum
  if has_key(s:breakpoints, key)
    call raddbg#RemoveBreakpoint(a:bnum, a:lnum)
  else
    call raddbg#AddBreakpoint(a:bnum, a:lnum)
  endif
endfunction

function! raddbg#AddBreakpoint(bnum, lnum) abort
  let file = fnamemodify(bufname(a:bnum), ':p')
  if empty(file)
    echohl ErrorMsg | echom '[raddbg] No file name for current buffer' | echohl None
    return
  endif
  let sid = s:sign_id_next
  let s:sign_id_next += 1
  let key = s:bufkey(a:bnum) . ':' . a:lnum
  let s:breakpoints[key] = sid
  if has('signs')
    execute 'sign place ' . sid . ' name=raddbg_breakpoint line=' . a:lnum . ' buffer=' . a:bnum
  endif
  " Mirror original behavior: clear, add WinMain function bp, then add location
  call s:ipc(['clear_breakpoints'])
  call s:ipc(['add_function_breakpoint', 'WinMain'])
  call s:ipc(['add_breakpoint', file . ':' . a:lnum])
endfunction

function! raddbg#RemoveBreakpoint(bnum, lnum) abort
  let key = s:bufkey(a:bnum) . ':' . a:lnum
  if has_key(s:breakpoints, key)
    let sid = remove(s:breakpoints, key)
    if has('signs')
      execute 'sign unplace ' . sid . ' buffer=' . a:bnum
    endif
    " On removal, original Python cleared all bps
    call s:ipc(['clear_breakpoints'])
  endif
endfunction

function! raddbg#Clear() abort
  if has('signs')
    for [key, sid] in items(copy(s:breakpoints))
      execute 'sign unplace ' . sid
    endfor
  endif
  let s:breakpoints = {}
  call s:ipc(['clear_breakpoints'])
endfunction

function! raddbg#Start() abort
  call s:ensure_raddbg_running()
  call s:ipc(['run'])
endfunction

function! raddbg#Stop() abort
  call s:ipc(['kill_all'])
endfunction

function! raddbg#Restart() abort
  call s:ipc(['restart'])
endfunction

function! raddbg#AddFunctionBreakpoint(name) abort
  call s:ipc(['add_function_breakpoint', a:name])
endfunction

function! raddbg#Status() abort
  echo '[raddbg] breakpoints: ' . len(keys(s:breakpoints))
endfunction

" Ensure the raddbg UI process is running (Windows: raddbg.exe); if not, start it.
function! s:ensure_raddbg_running() abort
  if !s:is_raddbg_running()
    call s:spawn_raddbg()
    " Wait briefly for the UI to initialize so IPC doesn't race.
    let l:tries = 10
    while l:tries > 0 && !s:is_raddbg_running()
      sleep 200m
      let l:tries -= 1
    endwhile
  endif
endfunction

function! s:raddbg_image_name() abort
  let l:exe = get(g:, 'raddbg_exe', 'raddbg')
  let l:img = fnamemodify(l:exe, ':t')
  if (has('win32') || has('win64')) && l:img !~? '\.exe$'
    let l:img = l:img . '.exe'
  endif
  return l:img
endfunction

function! s:is_raddbg_running() abort
  if has('win32') || has('win64')
    let l:img = s:raddbg_image_name()
    " Use tasklist to check if the process is present.
    let l:out = systemlist(['tasklist', '/FI', 'IMAGENAME eq ' . l:img])
    if v:shell_error != 0
      return 0
    endif
    for l:line in l:out
      if l:line =~? '^' . escape(l:img, '.*^$[]') . '\s'
        return 1
      endif
    endfor
    return 0
  else
    " Unix-like fallback: pgrep exact name
    let l:exe = get(g:, 'raddbg_exe', 'raddbg')
    call system('pgrep -x ' . shellescape(fnamemodify(l:exe, ':t')))
    return v:shell_error == 0
  endif
endfunction

function! s:spawn_raddbg() abort
  let l:exe = get(g:, 'raddbg_exe', 'raddbg')
  if has('win32') || has('win64')
    if !executable(l:exe)
      echohl ErrorMsg | echom '[raddbg] Cannot find executable: ' . l:exe | echohl None
      return
    endif
    " Launch detached using cmd start so Vim isn't blocked.
    call system(['cmd.exe', '/c', 'start', '', l:exe])
  else
    if exists('*job_start')
      call job_start([l:exe])
    else
      silent execute '!'.l:exe.' &'
    endif
  endif
endfunction

function! s:ipc(args) abort
  " Call: raddbg --ipc <args...>
  let exe = get(g:, 'raddbg_exe', 'raddbg')
  let cmd = [exe, '--ipc'] + a:args
  " Use system() (blocking). We intentionally ignore non-zero exit codes.
  call system(cmd)
endfunction
