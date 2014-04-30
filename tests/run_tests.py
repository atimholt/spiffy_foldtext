#!/usr/bin/env python3

import tempfile
import os
import subprocess

project_path = os.path.join(os.path.dirname(__file__), '../')
project_path = os.path.abspath(project_path)
print(project_path)

simple_vimrc = os.path.join(os.path.dirname(__file__), 'simple_vimrc.vim')

subprocess.call(['vim', '-u', simple_vimrc, '+Vader*'])

# vim: set noet ts=4 sts=4 sw=4 :
