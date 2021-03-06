#!/usr/bin/env python
from __future__ import unicode_literals

import youtube_dl
import sys
import logging

ydl_opts = {
    'cookiefile': '.cookie.txt',
    'skip_download':True,
    'extract_flat':True,
    'dump_single_json':True,
    'quiet':True,
    'socket-timeout':5,
    'restrictfilenames':True
}

if len(sys.argv) < 2:
    print "Too few arguments"
    raise UserWarning

with youtube_dl.YoutubeDL(ydl_opts) as ydl:
    ydl.download([sys.argv[1]])