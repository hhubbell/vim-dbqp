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

    silent! normal! "zy

    call writefile(getreg('z', 1, 1), '/tmp/odbc-persist-dat')
endfunction


function! dbqp#SendQuery()
    call s:HlQuery()

    let cmd = ['odbcpersist-query', '/tmp/odbc-persist-dat']

    let s:cur_win = win_getid()

    let s:bname = 'Scratch'
    let s:buf = bufnr(s:bname)

    if s:buf == -1
        exe 'split ' . s:bname

        setlocal buftype=nofile
        setlocal bufhidden=wipe
        setlocal noswapfile

    else
        let res_win = bufwinnr(s:buf)
        if res_win != -1
            execute res_win . 'wincmd w'
        else 
            execute 'sbuffer ' . s:buf
        endif

        silent! call deletebufline(s:bname, 1, '$')
    endif

    call appendbufline(s:bname, 0, 'Executing Query...')

    function! s:HandleQuery(ch, msg)
        " Clear out any messages in the buffer
        "call deletebufline(s:bname, 1)
        "call appendbufline(s:bname, 1, 'Execution Complete.')

        call appendbufline(s:bname, '$', a:msg)
        
        " FIXME: appendbufline starts at line 2 because line 1 exists but is
        " blank. So we delete the empty line 1
        "call deletebufline(s:bname, 1)
    endfunction

    function! s:HandleQueryEnd(ch, e_code)
        call deletebufline(s:bname, 1)
        call appendbufline(s:bname, 0, 'Execution Complete.')

        if s:cur_win != win_getid() && s:cur_win > 0
            call win_gotoid(s:cur_win)
        endif
    endfunction

    call job_start(cmd, {
        \ 'out_cb': function('s:HandleQuery'),
        \ 'exit_cb': function('s:HandleQueryEnd')
        \ })

endfunction

