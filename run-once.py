#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
from os import walk
import fnmatch
import sys
import subprocess

if len(sys.argv) >= 2:
    strPath = sys.argv[1]
else:
    strPath = '.'

g_fVerbose            = False
g_aFileExtToTranscode = ('.mp4', '.avi', '.mpg', '.wmv', '.mkv')
g_aFileSuffixesToSkip = ("_original", "_transcoded")

print('Handling path: %s' % strPath)

for (strDirPath, aDirNames, aFiles) in walk(strPath):
    for strFileName in aFiles:
        fHandled = False
        strFilePathAbs = strDirPath + '/' + strFileName
        if strFilePathAbs.lower().endswith(g_aFileExtToTranscode):
            strFileNameNoExt = os.path.splitext(strFilePathAbs)[0]
            if not strFileNameNoExt.lower().endswith(g_aFileSuffixesToSkip):
                print('Handling: %s' % strFilePathAbs)
                subprocess.call(['transcode.sh', strFilePathAbs])
                fHandled = True

        if not fHandled \
           and g_fVerbose:
            print('Skipping: %s' % strFilePathAbs)
