#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright 2010 Yohei Sasaki <yssk22@gmail.com>
#
# This software is licensed as described in the file LICENSE, which
# you should have received as part of this distribution.

import os
import sys
import unittest

sys.path.append(os.path.join(os.path.dirname(__file__), "../../"))
import webjourney

class ConfigTestCase(unittest.TestCase):
    def setUp(self):
        self.config = webjourney.WjConfig(webjourney.CONTAINER_CONF_PATH)
        pass

    def test_container_url(self):
        self.assertEqual(self.config.container_url, 
                         u"http://admin:password@localhost:5984/webjourney-container")

    def test_test_container_url(self):
        self.assertEqual(self.config.test_container_url, 
                         u"http://admin:password@localhost:5984/webjourney-container-test")

    def test_site_top_url(self):
        self.assertEqual(self.config.site_top_url, 
                         u"http://localhost/webjourney-container/_design/webjourney/_show/top")

        
if __name__ == '__main__':
    unittest.main()
