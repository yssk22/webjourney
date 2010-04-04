# -*- coding: utf-8 -*-
# Copyright 2010 Yohei Sasaki <yssk22@gmail.com>
#
# This software is licensed as described in the file LICENSE, which
# you should have received as part of this distribution.
import subprocess

def push(dir, url):
    cmd = "cd %s && couchapp push . %s" % (dir, url)
    p = subprocess.Popen(cmd, shell=True,
                         stdin=subprocess.PIPE, 
                         stdout=subprocess.PIPE, 
                         stderr=subprocess.PIPE)
    p.wait()
    
    if p.returncode != 0:
        print p.stderr.read()
        print "'couchapp push' fails (in %s)." % dir
        exit(1)

    return p
