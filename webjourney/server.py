# -*- coding: utf-8 -*-
# Copyright 2010 Yohei Sasaki <yssk22@gmail.com>
#
# This software is licensed as described in the file LICENSE, which
# you should have received as part of this distribution.

import couchdbkit
from urlparse import urlparse

class Server(couchdbkit.Server):
    def add_authorization(self, obj_auth):
        # monkey patch for add_authorization
        self.res.add_filter(obj_auth)

def getDatabase(url):
    url = urlparse(url)
    s =  Server("%s://%s" % (url.scheme,url.netloc)) 
    return s[url.path[1:]]
    
