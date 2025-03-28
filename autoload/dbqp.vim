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

function! dbq#SendQuery()
    call s:HlQuery()

    let result = system("odbcpersist-query < /tmp/odbc-persist-dat")
    
    echo result
endfunction

