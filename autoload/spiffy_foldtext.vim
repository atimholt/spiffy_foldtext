" Justification for this file's existence: some people use folds way less
" frequently than I do.

" Also, pretend this file is an object, okay? With its script-local variables
" and all.

let s:functions = [
    \ [ 1, '\([^%]\+\)'    , 'l:matchlist[1]'                 ],
    \ [ 0, '%%'            , '%'                              ],
    \ [ 0, '%c'            , 'l:line1_text'                   ],
    \ [ 0, '%C'            , 's:FillWhitespace(l:line1_text)' ],
    \ [ 0, '%<'            , 's:SplitMark(len(l:return_val))' ],
    \ [ 1, '%f{\([^}]*\)}' , 's:FillMark(len(s:parsed_so_far), l:matchlist[1])' ],
    \ [ 0, '%\(\d*\)n'     , 's:FormattedLineCount(l:matchlist[1])' ],
    \ [ 1, '%l{\([^}]*\)}' , 's:FoldlevelIndent(l:matchlist[1])' ],
    \ ]

function! spiffy_foldtext#SpiffyFoldText() "-v-
	let s:line1_text = spiffy_foldtext#CorrectlySpacify(getline(v:foldstart))
	let s:lines_count = v:foldend - v:foldstart + 1

	if !exists("s:parsed_string")
		let s:parsed_string = s:ParseFormatString(g:spf_txt.format)
	endif

	" Will (usually) be different every time this is run.
	let l:compiled_string = s:CompileFormatString(s:parsed_string)
	
	let l:still_to_parse = l:line1_text
	let l:return_val = ''
	while len(l:still_to_parse) != 0
		let l:nomatch = 1
		for [l:capture_val, l:fmt_str, l:callback] in s:functions
			exe 'let l:matchlist = matchlist(l:still_to_parse, ''^' . l:fmt_str . '\(.*\)$'')'
			
			if len(l:matchlist) != 0
				let l:nomatch = 0
				exe 'let l:return_val .= ' . l:callback
				let l:still_to_parse = l:matchlist[l:capture_val + 1]
				
				break
			endif
		endfor
		if l:nomatch
			let l:still_to_parse = strpart(l:still_to_parse, 1)
		endif
	endwhile
	
	let l:actual_winwidth = spiffy_foldtext#ActualWinwidth()
	if strdisplaywidth(l:return_val) >= l:actual_winwidth
		let l:before_split = strpart(l:return_val, 0, s:split_index)
		let l:after_split = strpart(l:return_val, s:split_index)
		
		let l:room_for_before = l:actual_winwidth - strdisplaywidth(l:after_split)
		"todo implement s:ChopToFit()
		let l:before_split = s:ChopToFit(l:before_split, l:room_for_before)
		
		let l:return_val = l:before_split . l:after_split
	else
		let l:before_fill = strpart(l:return_val, 0, s:fill_index)
		let l:after_fill = strpart(l:return_val, s:fill_index)
		
		let l:room_for_fill = l:actual_winwidth - strdisplaywidth(l:after_fill)
		"TODO the work is here. Do it.
		let l:return_val = l:before_fill . l:fill . l:after_fill
	endif
	
	return l:return_val
	
	"let l:end_text = g:spf_txt.left_of_linecount
	"let l:end_text .= printf("%10s", s:lines_count . ' lines')
	"let l:end_text .= g:spf_txt.foldlevel_indent_leftest
	"let l:end_text .= repeat(g:spf_txt.foldlevel_indent, (v:foldlevel - 1))
	"let l:end_text .= g:spf_txt.rightmost
	
	"let l:actual_winwidth = spiffy_foldtext#ActualWinwidth()
	"let l:kept_length = s:KeepLength(
		"\ l:line1_text,
		"\ l:actual_winwidth - strdisplaywidth(l:end_text) )
	
	"let l:return_val = strpart(l:line1_text, 0, l:kept_length)
	
	"let l:under_amount = l:actual_winwidth - (strdisplaywidth(l:return_val) +
											"\ strdisplaywidth(l:end_text)    )
	"if l:under_amount > 0
		"let l:return_val .= repeat(g:spf_txt.fillchar, l:under_amount)
	"endif
	
	"let l:return_val .= l:end_text
	
	"return l:return_val
endfunction "-^-
" spiffy_foldtext#SpiffyFoldText() helpers ─────────────────────────────-v-1

function! s:ParseFormatString(...) "-v-
	
endfunction "-^-

function! s:CompileFormatString(...) "-v-
	" Makes the string 
	
endfunction "-^-

function! s:FillWhitespace(...) "-v-
	let l:text_to_change = a:1
	
	" Dashes in the indentation
	let l:text_to_change = substitute(
	    \ l:text_to_change,
	    \ '^[ ]\+',
	    \ '\=repeat( g:spf_txt.fillchar, strlen(submatch(0)) - 1 ) . " " ',
	    \ 'e')
	
	" fill fairly wide whitespace regions
	let l:text_to_change = substitute(
	    \ l:text_to_change,
	    \ ' \([ ]\{3,}\) ',
	    \ '\=" " . repeat(g:spf_txt.fillchar, strlen(submatch(1))) . " " ',
	    \ 'g')
	
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

function! s:FoldlevelIndent(...) "-v-
	return repeat(a:1, v:foldlevel - 1)
endfunction "-^-

function! s:FormattedLineCount(...) "-v-
	exe 'return printf("%' . a:1 . 's", s:lines_count)'
endfunction "-^-

function! s:SplitMark(...) "-v-
	let s:split_index = a:1
	return ""
endfunction "-^-

function! s:FillMark(...) "-v-
	let s:fill_index = a:1
	let s:fillstr = a:2
	return ""
endfunction "-^-

function! s:ChopToFit(...) "-v-
	
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

