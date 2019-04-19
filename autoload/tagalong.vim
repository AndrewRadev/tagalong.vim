let s:opening_regex = '<\zs[^/>[:space:]][^>[:space:]]\+'
let s:closing_regex = '<\/\zs[^>[:space:]]\+\ze>'

function! tagalong#Init()
  if exists('b:tagalong_initialized')
    return
  endif
  let b:tagalong_initialized = 1

  nnoremap <buffer> <silent> c :call tagalong#Trigger()<cr>c
  nnoremap <buffer> <silent> C :call tagalong#Trigger()<cr>C
  nnoremap <buffer> <silent> v :call tagalong#Trigger()<cr>v
  nnoremap <buffer> <silent> i :call tagalong#Trigger()<cr>i
  nnoremap <buffer> <silent> a :call tagalong#Trigger()<cr>a

  autocmd InsertLeave <buffer> call tagalong#Apply()
endfunction

function! tagalong#Trigger()
  call inputsave()
  call tagalong#util#PushCursor()

  try
    let change = s:GetChangePositions()
    if change == {}
      " no change detected, nothing to do
      return
    endif

    let b:tag_change = change
  finally
    call tagalong#util#PopCursor()
    call inputrestore()
  endtry
endfunction

function! tagalong#Apply()
  if !exists('b:tag_change')
    return
  endif
  let change = b:tag_change | unlet b:tag_change

  call tagalong#util#PushCursor()

  try
    let change = s:FillChangeContents(change)
    if change == {}
      return
    endif

    undo

    " First the closing, in case the length changes:
    call setpos('.', change.closing_position)
    call tagalong#util#ReplaceMotion('va>', change.new_closing)

    " Then the opening tag:
    call setpos('.', change.opening_position)
    call tagalong#util#ReplaceMotion('va>', change.new_opening)

    silent! call repeat#set(":call tagalong#Reapply()\<cr>")

    " For tagalong#Reapply()
    let b:last_tag_change = change
  finally
    call tagalong#util#PopCursor()
  endtry
endfunction

function! tagalong#Reapply()
  if !exists('b:last_tag_change')
    return
  endif
  let last_change = b:last_tag_change
  let change = s:GetChangePositions()
  if change == {}
    return
  endif

  call tagalong#util#PushCursor()

  try
    " First the closing, in case the length changes:
    call setpos('.', change.closing_position)
    call tagalong#util#ReplaceMotion('va>', last_change.new_closing)

    " Then reapply the last "normal" operation on the opening, whatever it was
    call setpos('.', change.opening_position)
    normal! .

    silent! call repeat#set(":call tagalong#Reapply()\<cr>")
  finally
    call tagalong#util#PopCursor()
  endtry
endfunction

function! s:GetChangePositions()
  if tagalong#util#SearchUnderCursor(s:opening_regex)
    " We are on an opening tag
    let tag = matchstr(tagalong#util#GetMotion('va>'), s:opening_regex)

    let opening_position = getpos('.')
    normal %
    let closing_position = getpos('.')

    if opening_position != closing_position && tagalong#util#SearchUnderCursor('</\V'.tag.'>', 'n')
      " match seems to position cursor on the `/` of `</tag`
      let closing_position[2] += 1

      return {
            \ 'source':           'opening',
            \ 'opening_position': opening_position,
            \ 'closing_position': closing_position,
            \ }
    endif
  elseif tagalong#util#SearchUnderCursor(s:closing_regex)
    " We are on a closing tag
    let tag = matchstr(expand('<cWORD>'), s:closing_regex)

    let closing_position = getpos('.')
    normal %
    let opening_position = getpos('.')

    if opening_position != closing_position && tagalong#util#SearchUnderCursor('<\V'.tag.'\m\>', 'n')
      return {
            \ 'source':           'closing',
            \ 'opening_position': opening_position,
            \ 'closing_position': closing_position,
            \ }
    endif
  endif

  return {}
endfunction

function! s:FillChangeContents(change)
  let change = a:change

  if change.source == 'opening'
    let new_opening = tagalong#util#GetMotion('va>')
    let new_tag     = matchstr(new_opening, '^<\zs[^>[:space:]]\+')
    let new_closing = '</'.new_tag.'>'
  elseif change.source == 'closing'
    let new_closing = tagalong#util#GetMotion('va>')
    let new_tag     = matchstr(new_closing, '^<\/\zs[^>[:space:]]\+')

    call setpos('.', change.opening_position)
    let new_opening = tagalong#util#GetMotion('va>')
    let new_opening = substitute(new_opening, s:opening_regex, new_tag, '')
  else
    echoerr "Unexpected tag change source: " . change.source
    return
  endif

  if new_tag !~ '^[^<>]\+$'
    " we've had a change that resulted in something weird, like an empty
    " <></>, bail out
    return {}
  endif

  let change.new_tag     = new_tag
  let change.new_opening = new_opening
  let change.new_closing = new_closing

  return change
endfunction
