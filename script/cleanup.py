#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright 2010 Yohei Sasaki <yssk22@gmail.com>
#
# This software is licensed as described in the file LICENSE, which
# you should have received as part of this distribution.
import os
import sys
import subprocess

sys.path.append(os.path.join(os.path.dirname(__file__), ".."))
import webjourney
import webjourney.server


db = webjourney.server.getDatabase(webjourney.config.container_url)
num_docs =  db.info()["doc_count"]
print "Container URL: %s" % webjourney.config.container_url
print "    Documents: %s" % num_docs
print ""

while True:
    r = raw_input("Are you sure to clean up data? [y/n]> ")
    if r == 'y':
        db.flush()
        break
    elif r == 'n':
        print "canceled."
        break
    else:
        print "Please answer 'y' or 'n'."
