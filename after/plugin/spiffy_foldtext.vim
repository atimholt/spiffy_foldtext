
if !exists("g:spf_txt")
	let g:spf_txt = {}
endif

if !exists("g:spf_txt.use_multibyte")
	let g:spf_txt.use_multibyte = 1
endif

let s:use_multibyte = g:spf_txt.use_multibyte && has('multi_byte')

if !exists("g:spf_txt.format")
	if s:use_multibyte
		let g:spf_txt.format = "%C  %<%f{═}╡ %4n lines ╞═%l{╤═}"
	else
		let g:spf_txt.format = "%C  %<%f{=}| %4n lines |=%l{/=}"
	endif
endif

" vim: set fmr=-v-,-^- fdm=marker list noet ts=4 sw=4 sts=4 :

