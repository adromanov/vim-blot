" Blot Vim Plugin - Assembly viewer for C++ files
" Author: Generated with Claude Code

if exists('g:loaded_blot_plugin')
    finish
endif
let g:loaded_blot_plugin = 1

" Configuration variables
if !exists('g:blot_executable')
    let g:blot_executable = 'blot'
endif


" Function to find blot executable
function! s:FindBlotExecutable()
    " Try global executable
    if executable(g:blot_executable)
        return g:blot_executable
    endif

    return ''
endfunction

" Function to run blot and get JSON output
function! s:RunBlot(filepath)
    let blot_exe = s:FindBlotExecutable()
    if empty(blot_exe)
        echoerr 'Blot executable not found. Please build the project or set g:blot_executable.'
        return {}
    endif

    let cmd = blot_exe . ' -d0 --json --demangle ' . shellescape(a:filepath)
    let output = system(cmd)

    if v:shell_error != 0
        echoerr 'Blot failed: ' . output
        return {}
    endif

    try
        return json_decode(output)
    catch
        echoerr 'Failed to parse JSON output from blot'
        return {}
    endtry
endfunction

" Function to create assembly buffer
function! s:CreateAssemblyBuffer(assembly_lines, source_filename, source_bufnr)
    " Create new vertical split on the right
    vertical rightbelow vnew

    " Configure buffer settings
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal filetype=asm
    setlocal nomodifiable
    setlocal listchars=tab:\ \ 
    " setlocal list

    " Store reference to source buffer
    let b:blot_source_bufnr = a:source_bufnr

    " Insert assembly lines
    setlocal modifiable
    call setline(1, a:assembly_lines)
    setlocal nomodifiable

    " Set buffer name
    silent! execute 'file! [Assembly:' . a:source_filename . ']'

    " Set up autocmd to cleanup source buffer variables when this buffer is closed
    augroup BlotCleanup
        autocmd! * <buffer>
        autocmd BufUnload <buffer> call s:CleanupSourceBuffer(expand('<abuf>'))
    augroup END

    " Set up syntax highlighting
    syntax on

    return [bufnr('%'), bufwinid('%')]
endfunction

" Function to highlight source-to-assembly mappings
function! s:HighlightMappings(line_mappings)
    " Get current line in source buffer
    let source_line = line('.')

    " Find corresponding assembly lines
    " line_mappings is an array of {source_line: N, asm_start: N, asm_end: N}
    let [assembly_bufnr, assembly_winid] = s:GetAssemblyBuffer()
    if assembly_bufnr != -1
        let current_buf = bufnr('%')
        let current_winid = win_findbuf(current_buf)[0]

        " Switch to assembly window
        call win_gotoid(assembly_winid)

        " Clear existing matches in assembly buffer
        call clearmatches()

        " Iterate through all mappings to find matches for current source line
        let first_match_line = -1
        for mapping in a:line_mappings
            if mapping.source_line == source_line
                let start_line = mapping.asm_start
                let end_line = mapping.asm_end

                " Remember the first matched line for scrolling
                if first_match_line == -1
                    let first_match_line = start_line
                endif

                " Highlight the assembly line range
                for line_num in range(start_line, end_line)
                    call matchadd('Search', '\%' . line_num . 'l')
                endfor
            endif
        endfor

        " Scroll to show the first matched line
        if first_match_line != -1
            execute 'normal! ' . first_match_line . 'Gzz'
        endif

        " Switch back to source buffer
        call win_gotoid(current_winid)
    endif
endfunction

" Function to get assembly buffer number and window ID
function! s:GetAssemblyBuffer()
    " Check if assembly buffer variables exist
    if !exists('b:blot_asm_bufnr')
        return [-1, -1]
    endif
    if !exists('b:blot_asm_winid')
        return [-1, -1]
    endif

    return [b:blot_asm_bufnr, b:blot_asm_winid]
endfunction

" Main function to show assembly
function! BlotShowAssembly()
    " Check if current file is a C++ file
    if &filetype != 'cpp' && &filetype != 'c'
        echoerr 'Blot only works with C/C++ files'
        return
    endif

    " Save current file if modified
    if &modified
        write
    endif

    let filepath = expand('%:p')
    let source_filename = expand('%:t')
    echo 'Running blot on ' . filepath . '...'

    " Run blot and get JSON
    let result = s:RunBlot(filepath)
    if empty(result)
        return
    endif

    " Check if we already have an assembly buffer
    let [assembly_bufnr, assembly_winid] = s:GetAssemblyBuffer()
    if assembly_bufnr != -1
        " Close existing assembly buffer
        execute 'bdelete ' . assembly_bufnr
    endif

    " Extract assembly data from blot result
    let assembly_lines = get(result, 'assembly', [])
    let line_mappings = get(result, 'line_mappings', {})

    if empty(assembly_lines)
        echoerr 'No assembly output from blot'
        return
    endif

    " Store the current buffer number (source buffer)
    let source_bufnr = bufnr('%')
    let source_winid = win_findbuf(source_bufnr)[0]

    " Create assembly buffer and get its info
    let [asm_bufnr, asm_winid] = s:CreateAssemblyBuffer(assembly_lines, source_filename, source_bufnr)

    " Store line mappings and assembly buffer info in source buffer
    call setbufvar(source_bufnr, 'blot_line_mappings', line_mappings)
    call setbufvar(source_bufnr, 'blot_asm_bufnr', asm_bufnr)
    call setbufvar(source_bufnr, 'blot_asm_winid', asm_winid)

    " Switch back to source buffer
    call win_gotoid(source_winid)

    " echo 'Assembly loaded. Use :BlotHighlight to highlight current line mappings.'
endfunction

" Function to highlight current line mappings
function! BlotHighlight()
    if b:blot_asm_bufnr == -1
        unlet b:blot_asm_bufnr
        unlet b:blot_asm_winid
        unlet b:blot_line_mappings
    endif

    if !exists('b:blot_line_mappings')
        echoerr 'No blot mappings available. Run :BlotShowAssembly first.'
        return
    endif

    call s:HighlightMappings(b:blot_line_mappings)
endfunction

" Function to cleanup source buffer variables when assembly buffer is closed
function! s:CleanupSourceBuffer(asm_bufnr)
    let l:asm_bufnr = str2nr(a:asm_bufnr)
    let source_bufnr = getbufvar(l:asm_bufnr, 'blot_source_bufnr')
    if source_bufnr != '' && bufexists(source_bufnr)
        call setbufvar(source_bufnr, 'blot_asm_bufnr', -1)
        call setbufvar(source_bufnr, 'blot_asm_winid', -1)
        call setbufvar(source_bufnr, 'blot_line_mappings', [])
    endif
endfunction

" Function to close assembly buffer
function! BlotClose()
    let [assembly_bufnr, _] = s:GetAssemblyBuffer()
    if assembly_bufnr != -1
        execute 'bdelete ' . assembly_bufnr
        echo 'Assembly buffer closed.'
    else
        echo 'No assembly buffer found.'
    endif
endfunction

" Commands
command! BlotShowAssembly call BlotShowAssembly()
command! BlotHighlight call BlotHighlight()
command! BlotClose call BlotClose()

" Default key mappings (can be overridden by user)
if !exists('g:blot_no_mappings')
    nnoremap <leader>ba :BlotShowAssembly<CR>
    nnoremap <leader>bh :BlotHighlight<CR>
    nnoremap <leader>bc :BlotClose<CR>
endif
