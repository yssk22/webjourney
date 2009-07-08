// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License.  You may obtain a copy
// of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations under
// the License.

couchTests.attachments= function(debug) {
  var db = new CouchDB("test_suite_db");
  db.deleteDb();
  db.createDb();
  if (debug) debugger;

  var binAttDoc = {
    _id: "bin_doc",
    _attachments:{
      "foo.txt": {
        content_type:"text/plain",
        data: "VGhpcyBpcyBhIGJhc2U2NCBlbmNvZGVkIHRleHQ="
      }
    }
  }

  var save_response = db.save(binAttDoc);
  T(save_response.ok);

  var xhr = CouchDB.request("GET", "/test_suite_db/bin_doc/foo.txt");
  T(xhr.responseText == "This is a base64 encoded text");
  T(xhr.getResponseHeader("Content-Type") == "text/plain");
  T(xhr.getResponseHeader("Etag") == '"' + save_response.rev + '"');
  
  // empty attachment
  var binAttDoc2 = {
    _id: "bin_doc2",
    _attachments:{
      "foo.txt": {
        content_type:"text/plain",
        data: ""
      }
    }
  }

  T(db.save(binAttDoc2).ok);

  var xhr = CouchDB.request("GET", "/test_suite_db/bin_doc2/foo.txt");
  T(xhr.responseText.length == 0);
  T(xhr.getResponseHeader("Content-Type") == "text/plain");

  // test RESTful doc API

  var xhr = CouchDB.request("PUT", "/test_suite_db/bin_doc2/foo2.txt?rev=" + binAttDoc2._rev, {
    body:"This is no base64 encoded text",
    headers:{"Content-Type": "text/plain;charset=utf-8"}
  });
  T(xhr.status == 201);
  var rev = JSON.parse(xhr.responseText).rev;

  binAttDoc2 = db.open("bin_doc2");

  T(binAttDoc2._attachments["foo.txt"] !== undefined);
  T(binAttDoc2._attachments["foo2.txt"] !== undefined);
  T(binAttDoc2._attachments["foo2.txt"].content_type == "text/plain;charset=utf-8");
  T(binAttDoc2._attachments["foo2.txt"].length == 30);

  var xhr = CouchDB.request("GET", "/test_suite_db/bin_doc2/foo2.txt");
  T(xhr.responseText == "This is no base64 encoded text");
  T(xhr.getResponseHeader("Content-Type") == "text/plain;charset=utf-8");
  
  // test without rev, should fail
  var xhr = CouchDB.request("DELETE", "/test_suite_db/bin_doc2/foo2.txt");
  T(xhr.status == 409);

  // test with rev, should not fail
  var xhr = CouchDB.request("DELETE", "/test_suite_db/bin_doc2/foo2.txt?rev=" + rev);
  T(xhr.status == 200);
  
  
  // test binary data
  var bin_data = "JHAPDO*AU£PN ){(3u[d 93DQ9¡€])}    ææøo'∂ƒæ≤çæππ•¥∫¶®#†π¶®¥π€ª®˙π8np";
  var xhr = CouchDB.request("PUT", "/test_suite_db/bin_doc3/attachment.txt", {
    headers:{"Content-Type":"text/plain;charset=utf-8"},
    body:bin_data
  });
  T(xhr.status == 201);
  var rev = JSON.parse(xhr.responseText).rev;
  
  var xhr = CouchDB.request("GET", "/test_suite_db/bin_doc3/attachment.txt");
  T(xhr.responseText == bin_data);
  T(xhr.getResponseHeader("Content-Type") == "text/plain;charset=utf-8");
  
  var xhr = CouchDB.request("PUT", "/test_suite_db/bin_doc3/attachment.txt", {
    headers:{"Content-Type":"text/plain;charset=utf-8"},
    body:bin_data
  });
  T(xhr.status == 409);

  var xhr = CouchDB.request("PUT", "/test_suite_db/bin_doc3/attachment.txt?rev=" + rev, {
    headers:{"Content-Type":"text/plain;charset=utf-8"},
    body:bin_data
  });
  T(xhr.status == 201);
  var rev = JSON.parse(xhr.responseText).rev;

  var xhr = CouchDB.request("GET", "/test_suite_db/bin_doc3/attachment.txt");
  T(xhr.responseText == bin_data);
  T(xhr.getResponseHeader("Content-Type") == "text/plain;charset=utf-8");

  var xhr = CouchDB.request("GET", "/test_suite_db/bin_doc3/attachment.txt?rev=" + rev);
  T(xhr.responseText == bin_data);
  T(xhr.getResponseHeader("Content-Type") == "text/plain;charset=utf-8");

  var xhr = CouchDB.request("DELETE", "/test_suite_db/bin_doc3/attachment.txt?rev=" + rev);
  T(xhr.status == 200);
  
  var xhr = CouchDB.request("GET", "/test_suite_db/bin_doc3/attachment.txt?rev=" + rev);
  T(xhr.status == 404);

  // empty attachments
  var xhr = CouchDB.request("PUT", "/test_suite_db/bin_doc4/attachment.txt", {
    headers:{"Content-Type":"text/plain;charset=utf-8"},
    body:""
  });
  T(xhr.status == 201);
  var rev = JSON.parse(xhr.responseText).rev;

  var xhr = CouchDB.request("GET", "/test_suite_db/bin_doc4/attachment.txt");
  T(xhr.status == 200);
  T(xhr.responseText.length == 0);
  
  // overwrite previsously empty attachment
  var xhr = CouchDB.request("PUT", "/test_suite_db/bin_doc4/attachment.txt?rev=" + rev, {
    headers:{"Content-Type":"text/plain;charset=utf-8"},
    body:"This is a string"
  });
  T(xhr.status == 201);

  var xhr = CouchDB.request("GET", "/test_suite_db/bin_doc4/attachment.txt");
  T(xhr.status == 200);
  T(xhr.responseText == "This is a string");

};
