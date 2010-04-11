import os
import sys
import unittest

sys.path.append(os.path.join(os.path.dirname(__file__), "../../../"))
import webjourney.test_helper as helper

class TestValidateDocUpdate(helper.TestCaseBase):
    helper.reset_db(os.path.join(os.path.dirname(__file__), ".."))
    # fixtures = "foo"
    def test_type_validation(self):
        doc = self.assertSaveDoc(False, {"foo": "bar"})
        self.assertEqual(doc["reason"], "The 'type' field is required.");

        doc = self.assertSaveDoc(False, {"foo": "bar", "type": "foo"})
        self.assertEqual(doc["reason"], "Unknown type 'foo'.");

    def test_person_validation(self):
        doc = self.assertSaveDoc(False, {"foo": "bar", "type": "Person"});
        self.assertEqual(doc["reason"], "The 'displayName' field is required.");

        doc = self.assertSaveDoc(False, {"_id": "*foo", 
                                         "displayName": "foo", 
                                         "type": "Person"});
        self.assertEqual(doc["reason"], "The '_id' field is invalid.");

        self.login("yssk22", "password")
        doc = self.assertSaveDoc(False, {"_id": "p:foo", 
                                         "displayName": "foo", 
                                         "type": "Person"});
        self.assertEqual(doc["reason"], "The '_id' field is invalid.");

        doc = self.assertSaveDoc(True, {"_id": "p:yssk22", 
                                        "displayName": "foo", 
                                        "type": "Person"});

    def test_activity_validation(self):
        doc = self.assertSaveDoc(False, {"type": "Activity",
                                         "userId": "foo"});
        self.assertEqual(doc["reason"], "login required.");

        self.login("yssk22", "password")
        # _id field cannot be specified.
        doc = self.assertSaveDoc(False, {"_id": "p:foo", "type": "Activity",
                                         "userId": "yssk22" });
        self.assertEqual(doc["reason"], "The '_id' field is invalid format.");

        # userId field must be the same as user name.
        doc = self.assertSaveDoc(False, {"type": "Activity",
                                         "userId": "foo" });
        self.assertEqual(doc["reason"], "The 'userId' field is invalid.");

        doc = self.assertSaveDoc(True, {"type": "Activity",
                                        "userId": "yssk22" });
        

if __name__ == "__main__":
    unittest.main()
