"
"
"


" Manage connection state
let s:dbqp_connected = 0

"
function! s:HlQuery()
    " Move to nearest blank line
    while getline('.') =~ '\S' && line('.') > 1
        normal! k
    endwhile

    normal! V

    " Move to next semicolon
    while getline('.') !~ ";" && line('.') < line('$')
        normal! j
    endwhile

    " Write selected text to temp file
    silent! normal! "zy
    call writefile(getreg('z', 1, 1), '/tmp/odbc-persist-dat')
endfunction

" Manage creating or setting focus on the result buffer
" Param: bname buffer name
function! s:CreateOrFocusBuffer(bname)
    let l:buf = bufnr(a:bname)

    if l:buf == -1
        exe 'split ' . a:bname

        setlocal buftype=nofile
        setlocal bufhidden=wipe
        setlocal noswapfile
    else
        let l:res_win = bufwinnr(l:buf)

        if l:res_win != -1
            execute l:res_win . 'wincmd w'
        else 
            execute 'sbuffer ' . l:buf
        endif

        silent! call deletebufline(a:bname, 1, '$')
    endif
endfunction

" Interactively send a query based on the user's cursor
function! dbqp#SendQuery()
    if s:dbqp_connected == 0
        echohl ErrorMsg | echo "No database connected!" | echohl None
        return 0
    endif

    call s:HlQuery()

    let s:cur_win = win_getid()

    let s:bname = '-- dbqp --'
    call s:CreateOrFocusBuffer(s:bname)

    " FIXME: Not 100% sure echow is what I want to use
    echow 'Executing Query...'

    " Callback: HandleQuery
    "   Handles writing query results to the new or exsiting query result
    "   buffer
    function! s:HandleQuery(ch, msg)
        call appendbufline(s:bname, line('$') - 1, a:msg)
    endfunction

    " Callbakc: HandleQueryEnd
    "   Handles cleanup related to complete query commands
    function! s:HandleQueryEnd(ch, e_code)
        normal! 0gg

        if s:cur_win != win_getid() && s:cur_win > 0
            call win_gotoid(s:cur_win)
        endif

        echow 'Execution Complete.'
    endfunction

    let l:cmd = ["odbcpersist-query", "/tmp/odbc-persist-dat"]
    call job_start(cmd, {
        \ 'out_cb': function('s:HandleQuery'),
        \ 'exit_cb': function('s:HandleQueryEnd')
        \ })
endfunction

" Open a persistent connection to a SQL database
" Param: dsn connection string
function! dbqp#Connect(dsn)
    function! s:HandleConnectErr(ch, msg)
        let s:dbqp_connected = 0
        echohl ErrorMsg | echo a:msg | echohl None
    endfunction

    function! s:HandleDisconnect(ch, msg)
        let s:dbqp_connected = 0
        echohl ErrorMsg | echo "Disconnected." | echohl None
    endfunction

    let l:cmd = ["odbcpersist-start", "-c", a:dsn]
    call job_start(cmd, {
        \ 'stoponexit': 'term',
        \ 'err_cb': function('s:HandleConnectErr'),
        \ 'exit_cb': function('s:HandleDisconnect')
        \ })

    let s:dbqp_connected = 1
endfunction
