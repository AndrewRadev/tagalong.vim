" vim: foldmethod=marker

" Cursor stack manipulation {{{1
"
" In order to make the pattern of saving the cursor and restoring it
" afterwards easier, these functions implement a simple cursor stack. The
" basic usage is:
"
"   call tagalong#util#PushCursor()
"   " Do stuff that move the cursor around
"   call tagalong#util#PopCursor()
"
" function! tagalong#util#PushCursor() {{{2
"
" Adds the current cursor position to the cursor stack.
function! tagalong#util#PushCursor()
  if !exists('b:cursor_position_stack')
    let b:cursor_position_stack = []
  endif

  call add(b:cursor_position_stack, winsaveview())
endfunction

" function! tagalong#util#PopCursor() {{{2
"
" Restores the cursor to the latest position in the cursor stack, as added
" from the tagalong#util#PushCursor function. Removes the position from the stack.
function! tagalong#util#PopCursor()
  call winrestview(remove(b:cursor_position_stack, -1))
endfunction

" function! tagalong#util#DropCursor() {{{2
"
" Discards the last saved cursor position from the cursor stack.
" Note that if the cursor hasn't been saved at all, this will raise an error.
function! tagalong#util#DropCursor()
  call remove(b:cursor_position_stack, -1)
endfunction

" Text replacement {{{1
"
" Vim doesn't seem to have a whole lot of functions to aid in text replacement
" within a buffer. The ":normal!" command usually works just fine, but it
" could be difficult to maintain sometimes. These functions encapsulate a few
" common patterns for this.

" function! tagalong#util#ReplaceMotion(motion, text) {{{2
"
" Replace the normal mode "motion" with "text". This is mostly just a wrapper
" for a normal! command with a paste, but doesn't pollute any registers.
"
"   Examples:
"     call tagalong#util#ReplaceMotion('Va{', 'some text')
"     call tagalong#util#ReplaceMotion('V', 'replacement line')
"
" Note that the motion needs to include a visual mode key, like "V", "v" or
" "gv"
function! tagalong#util#ReplaceMotion(motion, text)
  " reset clipboard to avoid problems with 'unnamed' and 'autoselect'
  let saved_clipboard = &clipboard
  set clipboard=

  let saved_register_text = getreg('"', 1)
  let saved_register_type = getregtype('"')
  let saved_opening_visual = getpos("'<")
  let saved_closing_visual = getpos("'>")

  call setreg('"', a:text, 'v')
  exec 'silent normal! '.a:motion.'p'

  call setreg('"', saved_register_text, saved_register_type)
  call setpos("'<", saved_opening_visual)
  call setpos("'>", saved_closing_visual)
  let &clipboard = saved_clipboard
endfunction

" Text retrieval {{{1
"
" These functions are similar to the text replacement functions, only retrieve
" the text instead.
"
" function! tagalong#util#GetMotion(motion) {{{2
"
" Execute the normal mode motion "motion" and return the text it marks.
"
" Note that the motion needs to include a visual mode key, like "V", "v" or
" "gv"
function! tagalong#util#GetMotion(motion)
  call tagalong#util#PushCursor()

  let saved_register_text = getreg('z', 1)
  let saved_register_type = getregtype('z')
  let saved_opening_visual = getpos("'<")
  let saved_closing_visual = getpos("'>")

  let @z = ''
  exec 'silent normal! '.a:motion.'"zy'
  let text = @z

  if text == ''
    " nothing got selected, so we might still be in visual mode
    exe "normal! \<esc>"
  endif

  call setreg('z', saved_register_text, saved_register_type)
  call setpos("'<", saved_opening_visual)
  call setpos("'>", saved_closing_visual)
  call tagalong#util#PopCursor()

  return text
endfunction

" function! tagalong#util#GetByPosition(start, end) {{{2
"
" Fetch the area defined by the 'start' and 'end' positions. The positions
" should be compatible with the results of getpos():
"
"   [bufnum, lnum, col, off]
"
function! tagalong#util#GetByPosition(start, end)
  call setpos('.', a:start)
  call setpos("'z", a:end)

  return tagalong#util#GetMotion('v`z')
endfunction

" Searching for patterns {{{1
"
" function! tagalong#util#SearchUnderCursor(pattern, flags, skip) {{{2
"
" Searches for a match for the given pattern under the cursor. Returns the
" result of the |search()| call if a match was found, 0 otherwise.
"
" Moves the cursor unless the 'n' flag is given.
"
" The a:flags parameter can include one of "e", "p", "s", "n", which work the
" same way as the built-in |search()| call. Any other flags will be ignored.
"
function! tagalong#util#SearchUnderCursor(pattern, ...)
  let [match_start, match_end] = call('tagalong#util#SearchposUnderCursor', [a:pattern] + a:000)
  if match_start[0] > 0
    return match_start[0]
  else
    return 0
  endif
endfunction

" function! tagalong#util#SearchposUnderCursor(pattern, flags, skip) {{{2
"
" Searches for a match for the given pattern under the cursor. Returns the
" line and column positions of the match. If nothing was found,
" returns [0, 0].
"
" Moves the cursor unless the 'n' flag is given.
"
" Respects the skip expression if it's given.
"
" See tagalong#util#SearchUnderCursor for the behaviour of a:flags
"
function! tagalong#util#SearchposUnderCursor(pattern, ...)
  if a:0 >= 1
    let given_flags = a:1
  else
    let given_flags = ''
  endif

  if a:0 >= 2
    let skip = a:2
  else
    let skip = ''
  endif

  let lnum        = line('.')
  let col         = col('.')
  let pattern     = a:pattern
  let extra_flags = ''

  " handle any extra flags provided by the user
  for char in ['e', 'p', 's']
    if stridx(given_flags, char) >= 0
      let extra_flags .= char
    endif
  endfor

  call tagalong#util#PushCursor()

  " find the start of the pattern
  call search(pattern, 'bcW', lnum)
  let search_result = tagalong#util#SearchSkip(pattern, skip, 'cW'.extra_flags, lnum)
  if search_result <= 0
    call tagalong#util#PopCursor()
    return [0, 0]
  endif

  call tagalong#util#PushCursor()

  " find the end of the pattern
  if stridx(extra_flags, 'e') >= 0
    let match_end = [line('.'), col('.')]

    call tagalong#util#PushCursor()
    call tagalong#util#SearchSkip(pattern, skip, 'cWb', lnum)
    let match_start = [line('.'), col('.')]
    call tagalong#util#PopCursor()
  else
    let match_start = [line('.'), col('.')]
    call tagalong#util#SearchSkip(pattern, skip, 'cWe', lnum)
    let match_end = [line('.'), col('.')]
  end

  " set the end of the pattern to the next character, or EOL. Extra logic
  " is for multibyte characters.
  let saved_whichwrap = &whichwrap
  set whichwrap-=l
  normal! l
  let &whichwrap = saved_whichwrap

  if col('.') == match_end[1]
    " no movement, we must be at the end
    let match_end[1] = col('$')
  else
    let match_end[1] = col('.')
  endif
  call tagalong#util#PopCursor()

  if !tagalong#util#PosBetween([lnum, col], match_start, match_end)
    " then the cursor is not in the pattern
    call tagalong#util#PopCursor()
    return [0, 0]
  else
    " a match has been found
    if stridx(given_flags, 'n') >= 0
      call tagalong#util#PopCursor()
    else
      call tagalong#util#DropCursor()
    endif

    return match_start
  endif
endfunction

" function! tagalong#util#SearchSkip(pattern, skip, ...) {{{2
" A partial replacement to search() that consults a skip pattern when
" performing a search, just like searchpair().
"
" Note that it doesn't accept the "n" and "c" flags due to implementation
" difficulties.
function! tagalong#util#SearchSkip(pattern, skip, ...)
  " collect all of our arguments
  let pattern = a:pattern
  let skip    = a:skip

  if a:0 >= 1
    let flags = a:1
  else
    let flags = ''
  endif

  if stridx(flags, 'n') > -1
    echoerr "Doesn't work with 'n' flag, was given: ".flags
    return
  endif

  let stopline = (a:0 >= 2) ? a:2 : 0
  let timeout  = (a:0 >= 3) ? a:3 : 0

  " just delegate to search() directly if no skip expression was given
  if skip == ''
    return search(pattern, flags, stopline, timeout)
  endif

  " search for the pattern, skipping a match if necessary
  let skip_match = 1
  while skip_match
    let match = search(pattern, flags, stopline, timeout)

    " remove 'c' flag for any run after the first
    let flags = substitute(flags, 'c', '', 'g')

    if match && eval(skip)
      let skip_match = 1
    else
      let skip_match = 0
    endif
  endwhile

  return match
endfunction

" Checks if the given pos=[line, column] is within the given limits.
"
function! tagalong#util#PosBetween(pos, start, end)
  let start_bytepos = line2byte(a:start[0]) + a:start[1]
  let end_bytepos   = line2byte(a:end[0])   + a:end[1]
  let bytepos       = line2byte(a:pos[0])   + a:pos[1]

  return start_bytepos <= bytepos && bytepos < end_bytepos
endfunction
