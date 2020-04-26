if exists('g:loaded_tagalong') || &cp
  finish
endif

let g:loaded_tagalong = '0.2.1' " version number
let s:keepcpo = &cpo
set cpo&vim

if !exists('g:tagalong_filetypes')
  let g:tagalong_filetypes = ['html', 'xml', 'jsx', 'eruby', 'ejs', 'eco', 'php', 'htmldjango', 'javascriptreact', 'typescriptreact']
endif

if !exists('g:tagalong_additional_filetypes')
  let g:tagalong_additional_filetypes = []
endif

if !exists('g:tagalong_mappings')
  let g:tagalong_mappings = ['c', 'C', 'v', 'i', 'a']
endif

if !exists('g:tagalong_verbose')
  let g:tagalong_verbose = 0
endif

if !exists('g:tagalong_timeout')
  let g:tagalong_timeout = 500
endif

augroup tagalong
  autocmd!
  autocmd FileType * call s:InitIfSupportedFiletype(expand('<amatch>'))
augroup END

" Manually enable/disable the plugin
command TagalongInit   call tagalong#Init()
command TagalongDeinit call tagalong#Deinit()

" needed for silent execution of the . operator
nnoremap <silent> <Plug>TagalongReapply :call tagalong#Reapply()<cr>

" Needed in order to handle dot-filetypes like "javascript.jsx" or
" "custom.html".
function s:InitIfSupportedFiletype(filetype_string)
  for filetype in split(a:filetype_string, '\.')
    if index(g:tagalong_filetypes, filetype) >= 0 ||
          \ index(g:tagalong_additional_filetypes, filetype) >= 0
      call tagalong#Init()
      return
    endif
  endfor
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
