" vim-dbqp
"
" Vim Database Query Persist/Database Query Plugin
"
" Start and maintain connections to databases. Send queries interactively and
" print the results to a new buffer.
"


" Manage connection state
let g:dbqp_connected = 0

" Define query execution SignColumn indicator
sign define dbqp_exec numhl=SignColumn texthl=SignColumn text=>>


" Mark a query for execution by searching for the start and end of the query,
" and writing the contents of this selection to a temporary file. Mark this
" range by placing a 'sign' indicating the currently running query.
" FIXME: Currently, we mark the blank line as part of the selection.
" Return: int last line of selection
function! s:HlQuery()
    " If we started on the semicolon, move up one line
    if getline('.') =~ ';'
        normal! k
    endif

    " Move up to the nearest semicolon
    while getline('.') !~ ';' && line('.') > 1
        normal! k
    endwhile

    " If we landed on the semicolon, move down one line. Otherwise, we're
    " likely at line 1, so we can start from there.
    if getline('.') =~ ';'
        normal! j
    endif

    " Continue moving down to the nearest non-blank line
    while getline('.') !~ '\S' && line('.') < line('$')
        normal! j
    endwhile

    let l:c_line = line('.')

    normal! V
    exe "sign place " . l:c_line . " line=" . l:c_line . " name=dbqp_exec buffer=" . bufnr('%')

    " Move to next semicolon
    while getline('.') !~ ";" && line('.') < line('$')
        normal! j
        let l:c_line = line('.')
        exe "sign place " . l:c_line . " line=" . l:c_line . " name=dbqp_exec buffer=" . bufnr('%')
    endwhile

    " Write selected text to temp file
    silent! normal! "zy
    call writefile(getreg('z', 1, 1), '/tmp/odbc-persist-dat')

    return l:c_line
endfunction

" Apply custom formatting to the result buffer. Defines header highlight rule
function! s:SynResults()
    syn match dbqpHeader /^\%1l.*$/
    hi link dbqpHeader CursorLine
endfunction

" Grab focus of the result buffer
" Param: bname buffer name
function! s:FocusBuffer(bname)
    let l:buf = bufnr(a:bname)

    if l:buf == -1
        echoerr "Tried to focus nonexistant buffer"
        return
    endif

    let l:res_win = bufwinnr(l:buf)

    if l:res_win != -1
        " FIXME: Does this always work if more than one split exists?
        exe l:res_win . 'wincmd w'
    else
        exe 'sbuffer ' . l:buf
    endif

    silent! call deletebufline(a:bname, 1, '$')
endfunction

" Manage creating or setting focus on the result buffer
" Param: bname buffer name
function! s:CreateOrFocusBuffer(bname)
    let l:buf = bufnr(a:bname)

    if l:buf == -1
        exe 'belowright split ' . a:bname

        setlocal buftype=nofile
        setlocal bufhidden=wipe
        setlocal noswapfile
    else
        call s:FocusBuffer(a:bname)
    endif
endfunction

" Interactively send a query based on the user's cursor
function! dbqp#SendQuery()
    if g:dbqp_connected == 0
        echohl ErrorMsg | echo "No database connected!" | echohl None
        return 0
    endif

    let s:jline = s:HlQuery()
    let s:cur_win = win_getid()

    let s:query_success = 1
    let s:bname = '-- dbqp --'

    call s:CreateOrFocusBuffer(s:bname)

    " FIXME: Not 100% sure echow is what I want to use
    redraw | echohl Normal | echo 'Executing Query...' | echohl None

    " Callback: HandleQuerySuccess
    " Handles writing query results to the new or existing query result buffer
    function! s:HandleQuerySuccess(ch, msg)
        call appendbufline(s:bname, line('$') - 1, a:msg)
        let s:query_success = 1
    endfunction

    " Callback: HanderQueryError
    " Handles writing error messages to the new or existing query result buffer
    function! s:HandleQueryError(ch, msg)
        call appendbufline(s:bname, line('$') - 1, a:msg)
        let s:query_success = 0
    endfunction

    " Callback: HandleQueryEnd
    " Handles cleanup related to complete query commands
    function! s:HandleQueryEnd(ch, e_code)
        " Reposition to the first row and apply syntax highlighting
        normal! 0gg
        set nowrap
        if s:query_success != 0
            call s:SynResults()
        endif

        if s:cur_win != win_getid() && s:cur_win > 0
            call win_gotoid(s:cur_win)
        endif

        exe "sign unplace * buffer=" . bufnr('%')
        exe s:jline

        if s:query_success != 0
            echohl MoreMsg | echo 'Execution Complete.' | echohl None
        else
            echohl ErrorMsg | echo 'Execution Failed.' | echohl None
        endif
    endfunction

    let l:cmd = ["odbcpersist-query", "/tmp/odbc-persist-dat"]
    call job_start(cmd, {
        \ 'out_cb': function('s:HandleQuerySuccess'),
        \ 'err_cb': function('s:HandleQueryError'),
        \ 'exit_cb': function('s:HandleQueryEnd')
        \ })
endfunction

" Open a persistent connection to a SQL database
" Param: dsn connection string
function! dbqp#Connect(dsn)
    " Callback: HandleConnectMsg
    " Display any messages that the daemon sends throught stdout
    function! s:HandleConnectMsg(ch, msg)
        echohl MoreMsg | echo a:msg | echohl None
    endfunction

    " Callback: HandleConnectErr
    " Report an error message on connection failure
    function! s:HandleConnectErr(ch, msg)
        let g:dbqp_connected = 0
        echohl ErrorMsg | echo a:msg | echohl None
    endfunction

    " Callback: HandleDisconnect
    " Report an error message on connection closure
    function! s:HandleDisconnect(ch, msg)
        let g:dbqp_connected = 0
        echohl ErrorMsg | echo "Disconnected." | echohl None
    endfunction

    let l:cmd = ["odbcpersist-start", "-c", a:dsn]
    call job_start(cmd, {
        \ 'stoponexit': 'term',
        \ 'out_cb': function('s:HandleConnectMsg'),
        \ 'err_cb': function('s:HandleConnectErr'),
        \ 'exit_cb': function('s:HandleDisconnect')
        \ })

    let g:dbqp_connected = 1
endfunction
