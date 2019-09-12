#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
from os import walk
import fnmatch
import sys
import subprocess

if len(sys.argv) >= 2:
    path = sys.argv[1]
else:
    path = '.'

print('Handling: %s' % path)

pattern = "*.mp4"

for (dirpath, dirnames, filenames) in walk(path):
    for fname in filenames:
        if fnmatch.fnmatch(fname, pattern):
            fname_abs = dirpath + '/' + fname
            subprocess.call(['./transcode.sh', fname_abs])
