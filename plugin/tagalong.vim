" Initialize matchit, a requirement
if !exists('g:loaded_matchit')
  if has(':packadd')
    packadd matchit
  else
    runtime macros/matchit.vim
  endif
endif
if !exists('g:loaded_matchit')
  " then loading it somehow failed, we can't continue
  finish
endif

if exists('g:loaded_tagalong') || &cp
  finish
endif

let g:loaded_tagalong = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

if !exists('g:tagalong_filetypes')
  let g:tagalong_filetypes = ['html']
endif

augroup tagalong
  autocmd!

  for filetype in g:tagalong_filetypes
    exe 'autocmd FileType '.filetype.' call tagalong#Init()'
  endfor
augroup END

" TODO (2019-04-14) Store and restore typeahead? (Fast typing)
" (inputsave/inputrestore)

" TODO (2019-04-14) Visual + c?
" TODO (2019-04-14) repeat.vim support
" TODO (2019-04-14) multichange support? Hack in direct support, or provide
" some form of callback? maparg?

let &cpo = s:keepcpo
unlet s:keepcpo
