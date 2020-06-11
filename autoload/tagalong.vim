let s:opening_regex     = '<\zs\k[^>/[:space:]]*'
let s:closing_regex     = '<\/\zs\k[^>[:space:]]*\ze>'
let s:opening_end_regex = '\%(\_[^>]\{-}\_[^\/]\)\=>'

function! tagalong#Init()
  if exists('b:tagalong_initialized')
    return
  endif
  let b:tagalong_initialized = 1

  for key in g:tagalong_mappings
    if type(key) == type({})
      " e.g. {'c': '<leader>c'}
      for [native_key, override_key] in items(key)
        exe 'nnoremap <buffer><silent> ' . override_key .
              \ ' :<c-u>call tagalong#Trigger("' . escape(native_key, '"') . '", v:count)<cr>'
      endfor
    else
      " it's just a key
      let mapping = maparg(key, 'n')
      if mapping == ''
        let mapping = key
      endif

      exe 'nnoremap <buffer><silent> ' . key .
            \ ' :<c-u>call tagalong#Trigger("' . escape(mapping, '"') . '", v:count)<cr>'
    endif
  endfor

  exe 'augroup tagalong_'.bufnr('%')
    autocmd!
    autocmd InsertLeave <buffer> call tagalong#Apply()
  augroup END
endfunction

function! tagalong#Deinit()
  if !exists('b:tagalong_initialized')
    return
  endif
  unlet b:tagalong_initialized

  for key in g:tagalong_mappings
    exe 'unmap <buffer> '.key
  endfor

  exe 'augroup tagalong_'.bufnr('%')
    autocmd!
  augroup END
endfunction

" Can be invoked in two main ways:
"
"   call tagalong#Trigger()
"   call tagalong#Trigger('<mapping>', '<count>')
"
" The first method will prepare a change to a matching tag once
" `tagalong#Apply` is invoked. The second will *also* run the mapping with the
" given count.
"
" The built-in mapping uses the second method, but the first could be used for
" more complicated changes.
"
function! tagalong#Trigger(...)
  let action       = a:0 >= 1 ? a:1 : ""
  let repeat_count = a:0 >= 2 ? a:2 : 0

  if repeat_count > 0
    let mapping = repeat_count . action
  else
    let mapping = action
  end

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

    if mapping != ''
      call feedkeys(mapping, 'ni')
    endif
  endtry
endfunction

" If a tag change has already been prepared with `tagalong#Trigger`, apply it
" to the matching tag.
"
function! tagalong#Apply()
  if exists('b:tagalong_timeout_warning')
    echomsg b:tagalong_timeout_warning
    unlet b:tagalong_timeout_warning
  endif

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

" Repeat the last tag change in a different location.
"
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
    if change.source == 'closing'
      " We can safely just replace the contents:
      " First the closing, in case the length changes:
      call setpos('.', change.closing_position)
      call tagalong#util#ReplaceMotion('va>', change.new_closing)

      " Then the opening tag:
      call setpos('.', change.opening_position)
      call tagalong#util#ReplaceMotion('va>', change.new_opening)
    elseif change.source == 'opening'
      " First, reapply the last "normal" operation, whatever it was
      let old_opening = tagalong#util#GetMotion('va>')
      let old_tag     = matchstr(old_opening, s:opening_regex)
      normal! .
      let new_opening = tagalong#util#GetMotion('va>')
      let new_tag     = matchstr(new_opening, s:opening_regex)

      if old_tag ==# new_tag
        " then there's nothing else to do
        silent! call repeat#set("\<Plug>TagalongReapply")
        return
      endif

      if change.opening_position[1] == change.closing_position[1]
        " lines are the same, we need to readjust the closing position now
        let delta = len(new_opening) - len(old_opening)
        let change.closing_position[2] += delta
      endif

      " Change the (potentially updated) closing position
      call setpos('.', change.closing_position)
      call tagalong#util#ReplaceMotion('va>', last_change.new_closing)
    else
      echoerr "Unexpected tag change source: " . change.source
    endif

    silent! call repeat#set("\<Plug>TagalongReapply")
  finally
    call tagalong#util#PopCursor()
  endtry
endfunction

function! s:GetChangePositions()
  call tagalong#util#PushCursor()

  try
    if tagalong#util#SearchUnderCursor(s:opening_regex.s:opening_end_regex)
      " We are on an opening tag
      let tag = matchstr(tagalong#util#GetMotion('va>'), s:opening_regex)

      let opening_position = getpos('.')
      let start_jump_time = reltime()
      if s:JumpPair('forwards', tag) <= 0
        if g:tagalong_verbose &&
              \ g:tagalong_timeout > 0 &&
              \ reltimefloat(reltime(start_jump_time)) * 1000 >= g:tagalong_timeout
          let b:tagalong_timeout_warning =
                \ "Tagalong: Closing tag NOT updated, search timed out: ".tag
        endif
        return {}
      endif
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
      let start_jump_time = reltime()
      if s:JumpPair('backwards', tag) <= 0
        if g:tagalong_verbose &&
              \ g:tagalong_timeout > 0 &&
              \ reltimefloat(reltime(start_jump_time)) * 1000 >= g:tagalong_timeout
          let b:tagalong_timeout_warning =
                \ "Tagalong: Opening tag NOT updated, search timed out: ".tag
        endif
        return {}
      endif
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
  finally
    call tagalong#util#PopCursor()
  endtry
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

  if new_tag ==# change.old_tag
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

" Reimplements matchit, since that seems to jump to li items from ul>li
" setups, for instance
function! s:JumpPair(direction, tag)
  if a:direction == 'forwards'
    let flags = 'W'
  elseif a:direction == 'backwards'
    let flags = 'bW'
  else
    echoerr "Unexpected direction source: " . a:direction
    return 0
  endif

  let start_pattern = '<\zs\V'   . a:tag . '\m' . s:opening_end_regex
  let end_pattern   = '<\/\zs\V' . a:tag . '\m>'

  return searchpair(start_pattern, '', end_pattern, flags, '', 0, g:tagalong_timeout)
endfunction
