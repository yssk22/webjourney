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

couchTests.etags_views = function(debug) {
  var db = new CouchDB("test_suite_db");
  db.deleteDb();
  db.createDb();
  if (debug) debugger;
  
  var designDoc = {
    _id:"_design/etags",
    language: "javascript",
    views : {
      basicView : {
        map : stringFun(function(doc) {
          emit(doc.integer, doc.string);
        })
      },
      withReduce : {
        map : stringFun(function(doc) {
          emit(doc.integer, doc.string);
        }),
        reduce : stringFun(function(keys, values, rereduce) {
          if (rereduce) {
            return sum(values);
          } else {
            return values.length;
          }
        })
      }
    }
  }
  T(db.save(designDoc).ok);
  var xhr;
  var docs = makeDocs(0, 10);
  db.bulkSave(docs);
  
  // verify get w/Etag on map view
  xhr = CouchDB.request("GET", "/test_suite_db/_design/etags/_view/basicView");
  T(xhr.status == 200);
  var etag = xhr.getResponseHeader("etag");
  xhr = CouchDB.request("GET", "/test_suite_db/_design/etags/_view/basicView", {
    headers: {"if-none-match": etag}
  });
  T(xhr.status == 304);
  // TODO GET with keys (when that is available)
  
  // reduce view
  xhr = CouchDB.request("GET", "/test_suite_db/_design/etags/_view/withReduce");
  T(xhr.status == 200);
  var etag = xhr.getResponseHeader("etag");
  xhr = CouchDB.request("GET", "/test_suite_db/_design/etags/_view/withReduce", {
    headers: {"if-none-match": etag}
  });
  T(xhr.status == 304);
  
  // all docs
  xhr = CouchDB.request("GET", "/test_suite_db/_all_docs");
  T(xhr.status == 200);
  var etag = xhr.getResponseHeader("etag");
  xhr = CouchDB.request("GET", "/test_suite_db/_all_docs", {
    headers: {"if-none-match": etag}
  });
  T(xhr.status == 304);

  // by seq
  xhr = CouchDB.request("GET", "/test_suite_db/_all_docs_by_seq");
  T(xhr.status == 200);
  var etag = xhr.getResponseHeader("etag");
  xhr = CouchDB.request("GET", "/test_suite_db/_all_docs_by_seq", {
    headers: {"if-none-match": etag}
  });
  T(xhr.status == 304);    

  // list etag
  // in the list test for now
};
