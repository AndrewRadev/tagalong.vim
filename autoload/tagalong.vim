function! tagalong#Init()
  if exists('b:tagalong_initialized')
    return
  endif
  let b:tagalong_initialized = 1

  nnoremap <buffer> <silent> cw  :call tagalong#Trigger('w')<cr>cw
  nnoremap <buffer> <silent> ce  :call tagalong#Trigger('e')<cr>ce
  nnoremap <buffer> <silent> cW  :call tagalong#Trigger('W')<cr>cW
  nnoremap <buffer> <silent> cE  :call tagalong#Trigger('E')<cr>cE
  nnoremap <buffer> <silent> ciw :call tagalong#Trigger('iw')<cr>ciw
  nnoremap <buffer> <silent> caw :call tagalong#Trigger('aw')<cr>caw
  nnoremap <buffer> <silent> ci< :call tagalong#Trigger('i<')<cr>ci<
  nnoremap <buffer> <silent> ci> :call tagalong#Trigger('i>')<cr>ci>
  nnoremap <buffer> <silent> ct> :call tagalong#Trigger('t>')<cr>ct>

  autocmd InsertLeave <buffer> call tagalong#Apply()
endfunction

function! tagalong#Trigger(motion)
  call inputsave()

  call tagalong#util#PushCursor()
  let motion = a:motion
  if motion ==# 'w'
    " special case implemented by Vim
    let motion = 'e'
  elseif motion ==# 'W'
    let motion = 'E'
  endif

  if tagalong#util#SearchUnderCursor('<\zs[^/>[:space:]]\+')
    " We are on an opening tag
    let tag = matchstr(tagalong#util#GetMotion('vi>'), '^[^>[:space:]]\+')

    let opening_position = getpos('.')
    normal %
    let closing_position = getpos('.')

    if opening_position != closing_position && tagalong#util#SearchUnderCursor('</\V'.tag.'>', 'n')
      " match seems to position cursor on the `/` of `</tag`
      let closing_position[2] += 1

      let b:tag_change = {
            \ 'motion':           motion,
            \ 'source':           'opening',
            \ 'old_tag':          tag,
            \ 'opening_position': opening_position,
            \ 'closing_position': closing_position,
            \ }
    endif
  elseif tagalong#util#SearchUnderCursor('<\/\zs\S\+>')
    " We are on a closing tag
    let tag = matchstr(expand('<cWORD>'), '</\zs\S\+\ze>')

    let closing_position = getpos('.')
    normal %
    let opening_position = getpos('.')

    if opening_position != closing_position && tagalong#util#SearchUnderCursor('<\V'.tag.'\m\>', 'n')
      let b:tag_change = {
            \ 'motion':           motion,
            \ 'source':           'closing',
            \ 'old_tag':          tag,
            \ 'opening_position': opening_position,
            \ 'closing_position': closing_position,
            \ }
    endif
  endif

  call tagalong#util#PopCursor()

  call inputrestore()
endfunction

function! tagalong#Apply()
  if !exists('b:tag_change')
    return
  endif
  let change = b:tag_change | unlet b:tag_change
  let b:last_tag_change = change

  call tagalong#util#PushCursor()

  try
    if change.source == 'opening'
      let new_content = tagalong#util#GetByPosition(change.opening_position, getpos('.'))
      let new_tag     = matchstr(new_content, '^\s*\zs\S\+')
    elseif change.source == 'closing'
      let new_content = tagalong#util#GetByPosition(change.closing_position, getpos('.'))
      let new_tag     = new_content
    else
      echoerr "Unexpected tag change source: " . change.source
      return
    endif

    " Debug change

    if new_tag !~ '^[^</>]\+$'
      " we've had a change that resulted in something weird, like an empty
      " <></>, bail out
      return
    endif

    undo

    " First the closing, in case the length changes:
    call setpos('.', change.closing_position)
    call tagalong#util#ReplaceMotion('vi>', '/'.new_tag)

    " Then the opening tag:
    call setpos('.', change.opening_position)
    call tagalong#util#ReplaceMotion('v' . change.motion, new_content)

    silent! call repeat#set(":call tagalong#Reapply()\<cr>")
  finally
    call tagalong#util#PopCursor()
  endtry
endfunction

function! tagalong#Reapply()
  " TODO (2019-04-15) Get b:last_tag_change's replacement text, update
  " everything else
endfunction
