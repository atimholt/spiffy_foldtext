" Justification for this file's existence: some people use folds way less
" frequently than I do.

" Also, pretend this file is an object, okay? With its script-local variables
" and all.

" Not sure of the persistance of script-local variables.
if exists("s:empty_parse_result")
	unlet s:empty_parse_result
endif
let s:empty_parse_result = {
    \ 'split_mark' : -1,
    \ 'fill_mark'  : -1,
    \ 'fill_string' : '-',
    \ 'string_list' : [""]
    \}

let s:done_parsing = 0

if exists("s:parsed_string")
	unlet s:parsed_string
endif
let s:parsed_string = deepcopy(s:empty_parse_result)

function! s:parsed_string.AppendString(...)
	if type(a:1) = type("")
		s:parsed_string.string_list[-1] .= a:1
	else
		" Should be a list with a single executable string as its only element.
		" Allows delaying output until compiling for a particular fold.
		" Sticking it in an exe, on the right side of an assignment, MUST
		" return a string!
		" Funcrefs are inadequate here for various reasons.
		s:parsed_string.string_list += [a:1, ""]
	endif
endfunction

function! s:parsed_string.MarkSplit()
	s:parsed_string.split_mark = len(s:parsed_string.string_list)
	s:parsed_string.string_list += [""]
endfunction

function! s:parsed_string.MarkFill(...)
	s:parsed_string.fill_mark = len(s:parsed_string.string_list)
	s:parsed_string.fill_string = a:1
	s:parsed_string.string_list += [""]
endfunction

" Parsing Data "-v-
let s:literal_text = {
    \ 'capture_count' : 1,
    \ 'pattern'       : '\([^%]\+\)',
    \ 'callback'      : 's:parsed_string.AppendString(s:match_list[1])',
    \ }

let s:escaped_percent = {
    \ 'capture_count' : 0,
    \ 'pattern'       : '%%',
    \ 'callback'      : 's:parsed_string.AppendString("%")',
    \ }

let s:text_of_line = {
    \ 'capture_count' : 0,
    \ 'pattern'       : '%c',
    \ 'callback'      : 's:parsed_string.AppendString([''l:line1_text''])',
    \ }

let s:filled_text_of_line = {
    \ 'capture_count' : 0,
    \ 'pattern'       : '%C',
    \ 'callback'      : 's:parsed_string.AppendString([''s:FillWhitespace(l:line1_text)''])',
    \ }

" Where the right begins and is able to overlap the left, if the line's too big.
let s:split_mark = {
    \ 'capture_count' : 0,
    \ 'pattern'       : '%<',
    \ 'callback'      : 's:parsed_string.MarkSplit()',
    \ }

" Where the fill string fills, if the line's too short.
let s:fill_mark = {
    \ 'capture_count' : 1,
    \ 'pattern'       : '%f{\([^}]*\)}',
    \ 'callback'      : 's:parsed_string.MarkFill(s:match_list[1])',
    \ }

" Are these next two callbacks confusing enough for you? The idea is they need
" the s:match_list[1] value at the time of parsing. They're appended as lists
" of 1 member so they become compile-time callbacks (i.e., a list of string(s)
" is executed later). So part is a parse-time callback, and part is compile
" time.
"
" It's just hard to format it correctly here.
let s:formatted_line_count = {
    \ 'capture_count' : 1,
    \ 'pattern'       : '%\(\d*\)n',
    \ 'callback'      : 's:parsed_string.AppendString([printf("%'' . s:match_list[1] . ''s", s:lines_count)])',
    \ }

" Repeated string representing fold level (repeated v:foldlevel - 1 times)
let s:fold_level_indent = {
    \ 'capture_count' : 1,
    \ 'pattern'       : '%l{\([^}]*\)}',
    \ 'callback'      : 's:parsed_string.AppendString([repeat('' . s:match_list[1] .  '', v:foldlevel - 1)])',
    \ }


" Order of this list shouldn't matter unless there's deliberate pattern
" collision. There isn't. Still, it'll be slightly faster the one time it runs
" if the more common patterns are listed first.
let s:parse_data = [ s:literal_text, s:escaped_percent, s:text_of_line,
    \ s:filled_text_of_line, s:split_mark, s:fill_mark, s:formatted_line_count,
    \ s:fold_level_indent]
"-^-

function! spiffy_foldtext#SpiffyFoldText() "-v-
	if !s:done_parsing
		let s:parsed_string = s:ParseFormatString(g:spf_txt.format)
	endif
	
	return s:CompileFormatString(s:parsed_string)
	
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
	let l:return_val = deepcopy(s:empty_parse_result)
	
	let l:still_to_parse = a:1
	while len(l:still_to_parse) != 0
		let l:nomatch = 1
		for l:parse_datum in s:parse_data
			exe 'let s:match_list = matchlist(l:still_to_parse, ''^' . l:parse_datum.pattern . '\(.*\)$'')'
			
			if len(s:match_list) != 0
				let l:nomatch = 0
				
				exe l:parse_datum.callback
				
				let l:still_to_parse = s:match_list[l:capture_val + 1]
				break
			endif
		endfor
		if l:nomatch
			" This will only happen with a badly formed format string (or one
			" that uses patterns not available in their installed version).
			" The user really ought to fix their string, but this at least
			" keeps the loop from being infinite when they've made a mistake.
			"
			" The effect *should* be the ignoring of non-escaped %'s that
			" aren't part of a defined pattern.
			let l:still_to_parse = strpart(l:still_to_parse, 1)
		endif
	endwhile
	
	let s:done_parsing = 1
	return l:return_val
endfunction "-^-

function! s:CompileFormatString(...) "-v-
	let l:actual_winwidth = spiffy_foldtext#ActualWinwidth()
	let s:line1_text = spiffy_foldtext#CorrectlySpacify(getline(v:foldstart))
	let s:lines_count = v:foldend - v:foldstart + 1
	
	" Boy, this'd be cleaner with real OOP
	let l:callbacked_string = [""]
	let l:callbacked_fill_mark = -1
	let l:callbacked_split_mark = -1
	for i in range(len(s:parsed_string))
		if type(s:parsed_string[i]) = type([])
			exe 'let l:to_append = ' . s:parsed_string[i][0]
		else
			let l:to_append = l:string_member
		endif
		
		let l:callbacked_string[-1] += l:to_append
		
		if s:parsed_string.fill_mark == i
			let l:callbacked_fill_mark = len(l:callbacked_string)
			let l:callbacked_string += [""]
		endif
		
		if s:parsed_string.split_mark == i
			let l:callbacked_split_mark = len(l:callbacked_string)
			let l:callbacked_string += [""]
		endif
		
		if strdisplaywidth(join(l:callbacked_string, '')) > "TODO
			" TODO
		else
			" TODO
		endif
	endfor
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

