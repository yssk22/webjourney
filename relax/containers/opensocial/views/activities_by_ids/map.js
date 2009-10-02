function(doc){
  if( doc.type == "Activity" ){
    // Document mapping compliant for opensocial specification.
    // http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/REST-API.html#personFields
    doc["id"]      = doc._id;
    if(doc["bodyId"] == null ){
      doc["bodyId"] = doc._id + ":title";
    }
    doc["bodyId"]  = doc._id + ":body";
    if(doc["titleId"] == null){
      doc["titleId"] = doc._id + ":title";
    }
    emit([doc.userId, doc.appId, doc._id], doc);
  }
}