#!/usr/bin/env python3

import tempfile
import os
import subprocess

simple_vimrc_contents = """
	set nocompatible
	syntax on
	
	for dep in ['vader.vim', 'vim-repeat']
	execute 'set rtp+=' . finddir(dep, expand('~/.vim').'/**')
	endfor
	set rtp+=$SOURCE
	"""

with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8') as simple_vimrc:
	simple_vimrc.write(simple_vimrc_contents)
	#print(simple_vimrc_contents)
	
	#print(subprocess.check_output(['python', '-c', "\"print('hi')\""]))
	output = subprocess.check_output(
			['vim', '-u', simple_vimrc.name, '+Vader*'],
			stderr=subprocess.STDOUT,
			shell=True)
	print(output)

# vim: set noet ts=4 sts=4 sw=4 :
