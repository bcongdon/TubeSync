#!/usr/bin/env python
from __future__ import unicode_literals

import youtube_dl
import sys
import os

ydl_opts = {
    'cookiefile': '.cookie.txt',
    'restrictfilenames':True,
    'outtmpl':'%(title)s.%(ext)s',
    'consoletitle':True,
    'extract_flat':True,
    'noplaylist':True,
    'socket-timeout':5,
    'getfilename':True,
}
output_dir = ""
url = ""

if len(sys.argv) >= 3:
    url = sys.argv[1]
    output_dir = sys.argv[2]
else:
    print "Error: Not enough command line arguments."
    raise UserWarning

with youtube_dl.YoutubeDL(ydl_opts) as ydl:
    os.chdir(output_dir)
    ydl.download([url])