
if !exists("g:spf_txt")
	let g:spf_txt = {}
endif

if !exists("g:spf_txt.use_multibyte")
	let g:spf_txt.use_multibyte = 1
endif

if !exists("g:spf_txt.format")
	if s:use_multibyte
		let g:spf_txt.format = "%c  %<%f{═}╡ %4n lines ╞═%l{╤═}"
	else
		let g:spf_txt.format = "%c  %<%f{=}| %4n lines |=%l{/=}"
	endif
endif

let s:use_multibyte = g:spf_txt.use_multibyte && has('multi_byte')

if !exists("g:spf_txt.fillchar") || strdisplaywidth(g:spf_txt.fillchar) != 1
	let g:spf_txt.fillchar = ( s:use_multibyte ? '═' : '=' )
endif

if !exists("g:spf_txt.fill_whitespace")
	let g:spf_txt.fill_whitespace = 1
endif

if !exists("g:spf_txt.foldlevel_indent")
	let g:spf_txt.foldlevel_indent = ( s:use_multibyte ? '╤═' : '/=' )
endif

if !exists("g:spf_txt.foldlevel_indent_leftest")
	let g:spf_txt.foldlevel_indent_leftest = ( s:use_multibyte ? ' ╞═' : ' |=' )
endif

if !exists("g:spf_txt.left_of_linecount")
	let g:spf_txt.left_of_linecount = ( s:use_multibyte ? '╡ ' : '| ' )
endif

if !exists("g:sft_txt.rightmost")
	let g:spf_txt.rightmost = ( s:use_multibyte ? '' : '' )
endif

" vim: set fmr=-v-,-^- fdm=marker list noet ts=4 sw=4 sts=4 :

