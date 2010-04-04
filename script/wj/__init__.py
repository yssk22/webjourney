# -*- coding: utf-8 -*-
# Copyright 2010 Yohei Sasaki <yssk22@gmail.com>
#
# This software is licensed as described in the file LICENSE, which
# you should have received as part of this distribution.


import json
import os

APP_ROOT = os.path.join(os.path.dirname(__file__), "../../")
CONTAINER_CONF_PATH = os.path.join(APP_ROOT, "conf/webjourney.json") 
CONTAINER_LCONF_PATH = os.path.join(APP_ROOT, "conf/webjourney.local.json") 

class JsonConfig(object):
    def __init__(self, default_file, *files):
        self._config = self._load_config(default_file, *files)

    def _load_config(self, default_file, *files):
        _config = json.loads(open(default_file).read())
        for f in files:
            if os.path.exists(f):
                lconfig = json.loads(open(f).read())
                for key in _config.keys():
                    if lconfig.has_key(key):
                        _config[key].update(lconfig[key])
        return _config

class WjConfig(JsonConfig):
    def __init__(self):
        super(WjConfig, self).__init__(CONTAINER_CONF_PATH, 
                                       CONTAINER_LCONF_PATH)
    @property
    def container_url(self):
        """ Returns deployment container url
        """
        return "http://%s:%s@%s:%s/%s" % (self._config["deployment"]["admin"]["name"],
                                          self._config["deployment"]["admin"]["password"],
                                          self._config["deployment"]["host"],
                                          self._config["deployment"]["port"],
                                          self._config["db"]["container"])
    
    @property
    def site_top_url(self):
        top_url = "http://%s%s/%s/_design/webjourney/_show/top"
        shost = self._config["service"].get("host", "localhost") 
        sport = self._config["service"].get("port", 80) 
        if sport == 80:
            sport = ""
        else:
            sport = ":%s" % self._config["service"]["port"],
        return top_url % (shost,
                          sport,
                          self._config["db"]["container"])

config = WjConfig()        
