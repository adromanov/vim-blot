" C++ filetype plugin for Blot
" Automatically loaded for C++ files

" Auto-highlight mappings when cursor moves (optional)
if exists('g:blot_auto_highlight') && g:blot_auto_highlight
    augroup BlotAutoHighlight
        autocmd! * <buffer>
        autocmd CursorMoved <buffer> silent! call BlotHighlight()
    augroup END
endif

" Buffer-local mappings for C++ files
if !exists('g:blot_no_mappings')
    nnoremap <buffer> <leader>ba :BlotShowAssembly<CR>
    nnoremap <buffer> <leader>bh :BlotHighlight<CR>
    nnoremap <buffer> <leader>bc :BlotClose<CR>
endif
