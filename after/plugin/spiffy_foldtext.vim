
if !exists("g:spf_txt")
	let g:spf_txt = {}
endif

if !exists("g:spf_txt.fillchar") || strdisplaywidth(g:spf_txt.fillchar) != 1
	let g:spf_txt.fillchar = '═'
endif

if !exists("g:spf_txt.fill_whitespace")
	let g:spf_txt.fill_whitespace = 1
endif

" vim: set fmr=-v-,-^- fdm=marker list noet ts=4 sw=4 sts=4 :

