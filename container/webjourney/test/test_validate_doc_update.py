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

        doc = self.assertSaveDoc(True, {"foo": "bar", "type": "foo"})

        doc["type"] = "bar"
        doc = self.assertSaveDoc(False,  doc)
        self.assertEqual(doc["reason"], "The 'type' field cannot be changed.");

if __name__ == "__main__":
    unittest.main()
