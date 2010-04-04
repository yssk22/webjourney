#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright 2010 Yohei Sasaki <yssk22@gmail.com>
#
# This software is licensed as described in the file LICENSE, which
# you should have received as part of this distribution.
import os
import sys
import subprocess

import wj
from wj.couchapputil import push

# install container
print "Deploying container application to %s" % wj.config.container_url
push("container/webjourney", wj.config.container_url)
push("container/vendor", wj.config.container_url)

# TODO: install apps
print "Deploying open social applications to %s" % wj.config.container_url

print """
All installation processes have been completed successfully.
Please visit the top page at:

%s
""" % wj.config.site_top_url

exit(0)
