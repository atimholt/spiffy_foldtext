" Justification for this file's existence: some people use folds way less
" frequently than I do.

let s:my_fold_fill = '═'
function! spiffy_foldtext#SpiffyFoldText() "-v-
	let l:line1_text = spiffy_foldtext#CorrectlySpacify(getline(v:foldstart))
	
	let l:line1_text = s:FillWhitespace(l:line1_text)
	
	let l:lines_count = v:foldend - v:foldstart + 1
	let l:end_text = '╡ ' . printf("%10s", l:lines_count . ' lines') . ' ╞'
	let l:end_text .= repeat(s:my_fold_fill, 2 * v:foldlevel)
	
	let l:actual_winwidth = spiffy_foldtext#ActualWinwidth()
	let l:kept_length = s:KeepLength(
	    \ l:line1_text,
	    \ l:actual_winwidth - strdisplaywidth(l:end_text) )
	
	let l:return_val = strpart(l:line1_text, 0, l:kept_length)
	
	let l:under_amount = l:actual_winwidth - (strdisplaywidth(l:return_val) +
	                                        \ strdisplaywidth(l:end_text)    )
	if l:under_amount > 0
		let l:return_val .= repeat(s:my_fold_fill, l:under_amount)
	endif
	
	let l:return_val .= l:end_text
	
	return l:return_val
endfunction "-^-
" spiffy_foldtext#CorrectlySpacify() helpers ─────────────────────────────-v-1

function! s:FillWhitespace(...) "-v-
	let l:text_to_change = a:1
	
	" Dashes in the indentation
	let l:text_to_change = substitute(
	    \ l:text_to_change,
	    \ '^[ ]\+',
	    \ '\=repeat( s:my_fold_fill, strlen(submatch(0)) - 1 ) . " " ',
	    \ 'e')
	
	" fill fairly wide whitespace regions
	let l:text_to_change = substitute(
	    \ l:text_to_change,
	    \ ' \([ ]\{3,}\) ',
	    \ '\=" " . repeat(s:my_fold_fill, strlen(submatch(1))) . " " ',
	    \ 'g')
	
	let l:text_to_change .= "  "
	
	return l:text_to_change
endfunction "-^-

function! s:KeepLength(the_line, space_available) "-v-
	" 'asymptotic' arrival at the right value, due to multibytes.
	" VimL sucks
	let l:kept_length = len(a:the_line)
	let l:over_amount = 0
	let l:too_long = 1
	while l:too_long && (l:kept_length > 0)
		let l:start_display_width = strdisplaywidth(
		    \ strpart(l:the_line, 0, l:kept_length))
		let l:over_amount = l:start_display_width - a:space_available
		if l:over_amount > 0
			let l:kept_length -= max([1, l:over_amount])
		else
			let l:too_long = 0
		endif
	endwhile
	
	return l:kept_length
endfunction "-^-

" ────────────────────────────────────────────────────────────────────────-^-1

function! spiffy_foldtext#ActualWinwidth() "-v-
	" Finds the display width of that section of the window that actually shows
	" content.
	
	return winwidth(0) - s:NumberColumnWidth() - &foldcolumn - s:SignsWidth()
endfunction "-^-
" spiffy_foldtext#ActualWinwidth() helpers ───────────────────────────────-v-1

function! s:NumberColumnWidth() "-v-
	let l:number_col_width = 0
	
	" Find the width of the number column (0 if none)
	if &number
		" This assumes the number of lines is less than 10,000,000,000
		let l:number_col_width = max([strlen(line('$')) + 1, 3])
	elseif &relativenumber
		" I don’t know how tall a window has to be for this number to be bigger,
		" but I haven’t run into it.
		let l:number_col_width = 3
	endif
	
	if l:number_col_width != 0
		" It's always at least &numberwidth (if showing).
		let l:number_col_width = max([l:number_col_width, &numberwidth])
	endif
	
	return l:number_col_width
endfunction "-^-

function! s:SignsWidth() "-v-
	let l:signs_width = 0
	if has('signs')
		" This seems to be the only way to find out if the signs column is even
		" showing.
		let l:signs = []
		let l:signs_string = ''
		redir =>l:signs_string|exe "sil sign place buffer=".bufnr('')|redir end
		let l:signs = split(l:signs_string, "\n")[1:]
		
		if !empty(signs)
			let l:signs_width = 2
		endif
	endif
	
	return l:signs_width
endfunction "-^-

" ────────────────────────────────────────────────────────────────────────-^-1

function! spiffy_foldtext#CorrectlySpacify(...) "-v-
	" For converting tabs into spaces in such a way that the line is displayed
	" exactly as it would with tabs.
	
	let l:running_result = a:1
	let l:done = 0
	while !l:done
		" Replace first tab & everything after with nothing.
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

" vim: set fmr=-v-,-^- fdm=marker list noet ts=4 sw=4 sts=4 :

