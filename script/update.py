#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright 2010 Yohei Sasaki <yssk22@gmail.com>
#
# This software is licensed as described in the file LICENSE, which
# you should have received as part of this distribution.

import os
import sys
import getopt

sys.path.append(os.path.join(os.path.dirname(__file__), ".."))
import webjourney
from webjourney.couchapputil import push

def usage():
    sys.stderr.write('python update.py [-c <CONTAINER>] [-a <APP>]\n')

try:
    opts, args = getopt.getopt(sys.argv[1:], 
                               "hc:a:",
                               ["help", "container=", "app="])
except getopt.GetoptError:
    usage()
    exit(2)

app = None
container = None
for o, a in opts:
    if o in ("-h", "--help"):
        usage()
        exit()
    if o in ("-a", "--app"):
        app = a
    if o in ("-c", "--container"):
        container = a

if (app is None) and (container is None):
    sys.stderr.write("-c or -a must be specified.\n")
    usage()
    exit(1)

src = None
dst = None
if container:
    src = os.path.join(os.path.dirname(__file__), "../container",
                                container)
    dst = webjourney.config.container_url

else:
    src = os.path.join(os.path.dirname(__file__), "../app",
                                container)

if not os.path.exists(src):
    sys.stderr.write("couchapp root (%s) not found.\n" % src)
    exit(3)

p = push(src, dst)

print "Update: OK"

exit(0)
