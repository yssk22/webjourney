function(doc){
  if( doc.type == "AppData" ){
    // Document mapping compliant for opensocial specification.
    // http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/REST-API.html
    doc["id"] = doc._id;
    var map = {};
    map[doc.key] = doc.value;
    emit([doc.userId, doc.appId, doc.key], map);
  }
}