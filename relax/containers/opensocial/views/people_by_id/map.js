function(doc){
  if(doc.type == "Person"){
    // Document mapping compliant for opensocial specification.
    // http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/REST-API.html#personFields
    doc["id"] = doc._id;
    emit(doc._id, doc);
  }
}
