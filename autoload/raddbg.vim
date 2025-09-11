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

function! s:ipc(args) abort
  " Call: raddbg --ipc <args...>
  let exe = get(g:, 'raddbg_exe', 'raddbg')
  let cmd = [exe, '--ipc'] + a:args
  " Use system() (blocking). We intentionally ignore non-zero exit codes.
  call system(cmd)
endfunction
