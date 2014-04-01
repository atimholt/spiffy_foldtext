" Justification for this file's existence: some people use folds way less
" frequently than I do.

function! spiffy_foldtext#ActualWinwidth() "-v-
  " Assuming __current_window & __current_buffer only, for now. :/

  let l:number_col_width = 0
  if &number
    " Only works for the __current_buffer! (it’s the line('$') )
    let l:number_col_width =
        \ max([strlen(line('$')) + 1, 3])
    " This assumes the number of lines is less than 10,000,000,000
  elseif &relativenumber
    let l:number_col_width = 3
    " I don’t know how tall a window has to be for this number to be
    " bigger, but I haven’t run into it.
  endif
  if l:number_col_width != 0
    let l:number_col_width = max([l:number_col_width, &numberwidth])
  endif

  let l:signs_width = 0
  if has('signs')
    let l:signs = []
    let l:signs_string = ''
    redir =>l:signs_string|exe "sil sign place buffer=".bufnr('')|redir end
    let l:signs = split(l:signs_string, "\n")[1:]

    if !empty(signs)
      let l:signs_width = 2
    endif
  endif

  " Only works for the __current_window! (it’s the winwidth(0) )
  return winwidth(0) - l:number_col_width - &foldcolumn - l:signs_width
endfunction "-^-

function! spiffy_foldtext#CorrectlySpacify(...) "-v-
  let l:running_result = a:1
  let l:done = 0
  while !l:done
    " So ugly! substitute() is apparently the _only_ regex function in
    " vimscript
    let l:up_to_tab = substitute(l:running_result, '\t.*$', '', 'e')

    if l:running_result =~# '\t'
      let l:first_tab_col = strdisplaywidth(l:up_to_tab)
      let l:first_tab_dw = strdisplaywidth("\t", l:first_tab_col)

      let l:running_result = substitute(
            \ l:running_result,
            \ '\t',
            \ repeat(' ', l:first_tab_dw),
            \ 'e' )
    else
      let l:done = 1
    endif
  endwhile
  return l:running_result
endfunction "-^-

" TODO move this line?
set fillchars=vert:│,fold:═
let g:my_fold_fill = '═'
function! spiffy_foldtext#SpiffyFoldText() "-v-
  let l:line1_text = spiffy_foldtext#CorrectlySpacify(getline(v:foldstart))

  " Dashes in the indentation
  let l:line1_text = substitute(
      \ l:line1_text,
      \ '^[ ]\+',
      \ '\=repeat( g:my_fold_fill, strlen(submatch(0)) - 1 ) . " " ',
      \ 'e')
  " fill fairly wide whitespace regions
  let l:line1_text = substitute(
      \ l:line1_text,
      \ ' \([ ]\{3,}\) ',
      \ '\=" " . repeat(g:my_fold_fill, strlen(submatch(1))) . " " ',
      \ 'g')
  let l:line1_text .= "  "

  let l:lines_count = v:foldend - v:foldstart + 1
  let l:end_text = '╡ ' . printf("%10s", l:lines_count . ' lines') . ' ╞'
  let l:end_text .= repeat(g:my_fold_fill, 2 * v:foldlevel)

  " 'asymptotic' arrival at the right value, due to multibytes.
  " VimL sucks
  let l:kept_length = len(l:line1_text)
  let l:end_display_width = strdisplaywidth(l:end_text)
  let l:actual_winwidth = spiffy_foldtext#ActualWinwidth()
  let l:over_amount = 0
  let l:too_long = 1
  while l:too_long && (l:kept_length > 0)
    let l:start_display_width = strdisplaywidth(
        \ strpart(l:line1_text, 0, l:kept_length))
    let l:over_amount = (l:start_display_width + l:end_display_width) - l:actual_winwidth
    if l:over_amount > 0
      let l:kept_length -= max([1, l:over_amount])
      "let l:kept_length -= l:over_amount
    else
      let l:too_long = 0
    endif
  endwhile

  let l:return_val = strpart(l:line1_text, 0, l:kept_length)
  if l:over_amount < 0
    let l:return_val .= repeat(g:my_fold_fill, -1 * l:over_amount)
  endif
  let l:return_val .= l:end_text

  return l:return_val
endfunction "-^-

" vim: set fmr=-v-,-^- fdm=marker et ts=2 sw=2 sts=2 :

