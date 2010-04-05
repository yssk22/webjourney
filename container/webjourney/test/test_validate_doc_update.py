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
        

if __name__ == "__main__":
    unittest.main()
