let s:opening_regex = '<\zs\k[^>[:space:]]\+'
let s:closing_regex = '<\/\zs\k[^>[:space:]]\+\ze>'

function! tagalong#Init()
  if exists('b:tagalong_initialized')
    return
  endif
  let b:tagalong_initialized = 1

  for key in g:tagalong_mappings
    let mapping = maparg(key, 'n')
    if mapping == ''
      let mapping = key
    endif

    exe 'nnoremap <buffer> <silent> '.key.' :call tagalong#Trigger()<cr>'.mapping
  endfor

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

    silent undo

    " First the closing, in case the length changes:
    call setpos('.', change.closing_position)
    call tagalong#util#ReplaceMotion('va>', change.new_closing)

    " Then the opening tag:
    call setpos('.', change.opening_position)
    call tagalong#util#ReplaceMotion('va>', change.new_opening)

    silent! call repeat#set("\<Plug>TagalongReapply")

    if g:tagalong_verbose > 0
      if change.source == 'opening'
        echomsg "Tagalong: Closing tag changed to ".change.new_closing
      elseif change.source == 'closing'
        echomsg "Tagalong: Opening tag changed to ".change.new_opening
      endif
    endif

    " For tagalong#Reapply()
    let b:last_tag_change = change
  finally
    call tagalong#util#PopCursor()
  endtry
endfunction

function! tagalong#Reapply()
  if !exists('b:last_tag_change')
    normal! .
    return
  endif
  let last_change = b:last_tag_change
  let change = s:GetChangePositions()
  if change == {}
    normal! .
    return
  endif

  call tagalong#util#PushCursor()

  " Note: applying open -> adjust -> close, because the `.` operator seems to
  " reapply the visual-mode change otherwise, on v7.4. This doesn't happen on
  " > v8.0, but hard to say if this is a stable situation. Better to be safe.

  try
    " Reapply the last "normal" operation on the opening, whatever it was
    call setpos('.', change.opening_position)
    let old_opening = tagalong#util#GetMotion('va>')
    normal! .
    let new_opening = tagalong#util#GetMotion('va>')

    if change.opening_position[1] == change.closing_position[1]
      " lines are the same, we need to readjust the closing position now
      let delta = len(new_opening) - len(old_opening)
      let change.closing_position[2] += delta
    endif

    " Change the (potentially updated) closing position
    call setpos('.', change.closing_position)
    call tagalong#util#ReplaceMotion('va>', last_change.new_closing)

    silent! call repeat#set("\<Plug>TagalongReapply")
  finally
    call tagalong#util#PopCursor()
  endtry
endfunction

function! s:GetChangePositions()
  if tagalong#util#SearchUnderCursor(s:opening_regex.'.\{-}>')
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
            \ 'old_tag':          tag,
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
            \ 'old_tag':          tag,
            \ 'opening_position': opening_position,
            \ 'closing_position': closing_position,
            \ }
    endif
  endif

  return {}
endfunction

function! s:FillChangeContents(change)
  let change = a:change

  call tagalong#util#PushCursor()

  if change.source == 'opening'
    call setpos('.', change.opening_position)
    let new_opening = tagalong#util#GetMotion('va>')
    let new_tag     = matchstr(new_opening, '^<\zs[^>[:space:]]\+')
    let new_closing = '</'.new_tag.'>'
  elseif change.source == 'closing'
    call setpos('.', change.closing_position)
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
    call tagalong#util#PopCursor()
    return {}
  endif

  if new_tag == change.old_tag
    " nothing to change
    call tagalong#util#PopCursor()
    return {}
  endif

  let change.new_tag     = new_tag
  let change.new_opening = new_opening
  let change.new_closing = new_closing

  call tagalong#util#PopCursor()
  return change
endfunction
