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
from webjourney.couchapputil import push

# install container
print "Deploying container application to %s" % webjourney.config.container_url
push("container/webjourney", webjourney.config.container_url)
push("container/vendor", webjourney.config.container_url)

# TODO: install apps
print "Deploying open social applications to %s" % webjourney.config.container_url

print """
All installation processes have been completed successfully.
Please visit the top page at:

%s
""" % webjourney.config.site_top_url

exit(0)
