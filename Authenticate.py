#!/usr/bin/env python
from __future__ import unicode_literals

import youtube_dl
import sys

ydl_opts = {
    #'logger': MyLogger(),
    'cookiefile': '.cookie.txt',
    'skip_download':True,
    #'restrictfilenames':True,
    'outtmpl':'%(title)s.%(ext)s',
    #'progress_hooks':[title_hook],
    'consoletitle':True,
    'extract_flat':True,
    'socket-timeout':5,
}

if len(sys.argv) >= 2:
    ydl_opts["username"] = sys.argv[1]
if len(sys.argv) >= 3:
    ydl_opts["password"] = sys.argv[2]
if len(sys.argv) >= 4:
    ydl_opts["twofactor"] = sys.argv[3]


with youtube_dl.YoutubeDL(ydl_opts) as ydl:
    #Fast download to generate cookies file quickly
    ydl.download(["https://www.youtube.com/playlist?list=WL"])