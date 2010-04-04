import unittest
import json
import couchdbkit
from restkit import BasicAuth
from restkit.errors import ResourceError
from urlparse import urlparse, urlunparse


import webjourney
import couchapputil

class Server(couchdbkit.Server):
    def add_authorization(self, obj_auth):
        # monkey patch for add_authorization
        self.res.add_filter(obj_auth)

TEST_DB_URL = urlparse(webjourney.config.test_container_url)

Server  = Server("%s://%s" % (TEST_DB_URL.scheme, 
                              TEST_DB_URL.netloc))
TestDB = None

    
def reset_db(*app_dirs):
    try:
        Server.delete_db(TEST_DB_URL.path[1:])
    except couchdbkit.resource.ResourceNotFound, e:
        # ignore
        pass

    global TestDB
    TestDB = Server.create_db(TEST_DB_URL.path[1:])

    for dir in app_dirs:
        couchapputil.push(dir, urlunparse(TEST_DB_URL))

def load_fixtures(dir, reset = True):
    """ Loading fixtures from specified directory
    """
    pass


class TestCaseBase(unittest.TestCase):
    def setUp(self):
        self.db = TestDB
        # self.db.flush()
        fixtures = getattr(self, "fixtures", [])
        pass

    def tearDown(self):
        pass

    def assertSaveDoc(self, 
                      expect_succ = True, 
                      doc = {}, encode_attachments = True,
                      _raw_json = False, **params):
        """ Assert if the document is saved successfully or not.
        """
        try:
            ret = self.db.save_doc(doc, encode_attachments, _raw_json, **params)
            doc["_id"]  = ret["id"]
            doc["_rev"] = ret["rev"]
            if not expect_succ:
                self.fail("saveDoc Success: %s" % doc)
        except ResourceError, e:
            if expect_succ:
                self.fail("saveDoc Failure: %s" % e.response.body)
            doc = json.loads(e.response.body)
        return doc

    def assertSaveDocSucc(self, 
                          doc = {}, encode_attachments = True,
                          _raw_json = False, **params):
        """ Assert that the document is saved successfully.
        """
        self.assertSaveDoc(True, doc, encode_attachments, _raw_json, **params)


    def assertSaveDocFail(self, 
                          doc = {}, encode_attachments = True,
                          _raw_json = False, **params):
        """ Assert that the document is not saved.
        """
        self.assertSaveDoc(False, doc, encode_attachments, _raw_json, **params)


