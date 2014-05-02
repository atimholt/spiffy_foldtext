set nocompatible
syntax on
""
set guioptions=c
"TODO: generalize
set rtp+=~/.vim/neobundle/vader.vim/
execute 'set rtp+=' . expand('%:p:h:h')

let g:SpiffyFoldtext_format = "%c{=}  %<%f{=}| %4n lines |=%l{/=}"

