" Justification for this file's existence: some people use folds way less
" frequently than I do.

" Also, pretend this file is an object, okay? With its script-local variables
" and all.

" Variable default values -v-

" Not sure of the persistance of script-local variables.
if exists("s:parsed_string")
	unlet s:parsed_string
endif
let s:parsed_string = [""]

let s:done_parsing = 0
"-^-

function! s:AppendString(...) "-v-
	if type(a:1) == type("") && type(s:parsed_string[-1]) == type("")
		let s:parsed_string[-1] .= a:1
	else
		" Should be a list with a single executable string as its only element
		" (Or a string after such).
		" Allows delaying output until compiling for a particular fold.
		" Sticking it in an exe, on the right side of an assignment, MUST
		" return a string!
		" Funcrefs are inadequate here for various reasons.
		let s:parsed_string += [a:1]
	endif
endfunction "-^-

function! s:MarkSplit() "-v-
	let s:parsed_string.string_list += [{'mark' : 'split'}]
endfunction "-^-

function! s:MarkFill(...) "-v-
	let s:parsed_string.string_list += [{'mark' : 'fill', 'fill_string' : a:1}]
endfunction "-^-

" Parsing Data "-v-
let s:literal_text = {
    \ 'capture_count' : 1,
    \ 'pattern'       : '\([^%]\+\)',
    \ 'callback'      : 's:AppendString(s:match_list[1])',
    \ }

let s:escaped_percent = {
    \ 'capture_count' : 0,
    \ 'pattern'       : '%%',
    \ 'callback'      : 's:AppendString("%")',
    \ }

let s:text_of_line = {
    \ 'capture_count' : 0,
    \ 'pattern'       : '%c',
    \ 'callback'      : 's:AppendString([''l:line1_text''])',
    \ }

let s:filled_text_of_line = {
    \ 'capture_count' : 0,
    \ 'pattern'       : '%C',
    \ 'callback'      : 's:AppendString([''s:FillWhitespace(l:line1_text)''])',
    \ }

" Where the right begins and is able to overlap the left, if the line's too big.
let s:split_mark = {
    \ 'capture_count' : 0,
    \ 'pattern'       : '%<',
    \ 'callback'      : 's:MarkSplit()',
    \ }

" Where the fill string fills, if the line's too short.
let s:fill_mark = {
    \ 'capture_count' : 1,
    \ 'pattern'       : '%f{\([^}]*\)}',
    \ 'callback'      : 's:MarkFill(s:match_list[1])',
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
    \ 'callback'      : 's:AppendString([''printf("%'' . s:match_list[1] . ''s", s:lines_count)''])',
    \ }

" Repeated string representing fold level (repeated v:foldlevel - 1 times)
let s:fold_level_indent = {
    \ 'capture_count' : 1,
    \ 'pattern'       : '%l{\([^}]*\)}',
    \ 'callback'      : 's:AppendString([''repeat('' . s:match_list[1] .  '', v:foldlevel - 1)''])',
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
		call s:ParseFormatString(g:spf_txt.format)
	endif
	
	return s:CompileFormatString(s:parsed_string)
endfunction "-^-

function! s:ParseFormatString(...) "-v-
	let s:parsed_string = [""]
	
	let l:still_to_parse = a:1
	while len(l:still_to_parse) != 0
		let l:nomatch = 1
		for l:parse_datum in s:parse_data
			let l:full_pattern = '^' . l:parse_datum.pattern . '\(.*\)$'
			let s:match_list = matchlist(l:still_to_parse, l:full_pattern)
			
			if len(s:match_list) != 0
				let l:nomatch = 0
				
				exe 'call ' . l:parse_datum.callback
				
				let l:still_to_parse = s:match_list[l:parse_datum.capture_count + 1]
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
endfunction "-^-

function! s:CompileFormatString(...) "-v-
	let l:actual_winwidth = spiffy_foldtext#ActualWinwidth()
	let l:line1_text = spiffy_foldtext#CorrectlySpacify(getline(v:foldstart))
	let s:lines_count = v:foldend - v:foldstart + 1
	
	let l:callbacked_string = [""]
	for element in s:parsed_string
		if type(element) == type({})
			let l:callbacked_string += [element, ""]
		elseif type(element) == type([])
			" This is the notation for a compile-time callback.
			exe 'let l:callbacked_string[-1] .= ' . element[0]
		else
			let l:callbacked_string[-1] .= element
		endif
	endfor
	
	let l:length_so_far = s:LengthOfListsStrings(l:callbacked_string)
	if l:length_so_far > l:actual_winwidth
		let l:before_split = ""
		let l:after_split = ""
		let l:is_before_split = 1
		for element in l:callbacked_string
			if type(element) == type("")
				if l:is_before_split
					let l:before_split .= element
				else
					let l:after_split .= element
				endif
			elseif type(element) == type({}) && element.mark == 'split'
				let l:is_before_split = 0
			endif
		endfor
		
		let l:room_for_before = l:actual_winwidth - strdisplaywidth(l:after_split)
		let l:before_split = s:KeepLength(l:before_split, l:room_for_before)
		
		let l:return_val = l:before_split . l:after_split
	else
		let l:before_fill = ""
		let l:after_fill = ""
		let l:fill_string = "-"
		let l:is_before_fill = 1
		for element in l:callbacked_string
			if type(element) == type("")
				if l:is_before_fill
					let l:before_fill .= element
				else
					let l:after_fill .= element
				endif
			elseif type(element) == type({}) && element.mark == 'fill'
				let l:is_before_fill = 0
				let l:fill_string = element.fill_string
			endif
		endfor
		
		let l:room_for_fill = l:actual_winwidth - (strdisplaywidth(l:before_fill) + strdisplaywidth(l:after_fill))
		let l:whole_num_repeat = l:room_for_fill / strdisplaywidth(l:fill_string)
		let l:frac_part_repeat = l:room_for_fill % strdisplaywidth(l:fill_string)
		
		let l:fill = repeat(l:fill_string, l:whole_num_repeat)
		let l:fill .= s:KeepLength(l:fill_string, l:frac_part_repeat)
		
		let l:return_val = l:before_fill . l:fill . l:after_fill
	endif
	return return_val
endfunction "-^-

function! s:LengthOfListsStrings(...) "-v-
	let l:return_val = 0
	for element in a:1
		if type(element) = type("")
			let l:return_val .= strdisplaywidth(element)
		endif
	endfor
	return l:return_val
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
	
	return strpart(the_line, 0, l:kept_length)
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

