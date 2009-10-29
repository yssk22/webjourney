function(doc){
  if( doc.type == "AppData" ){
    // Document mapping compliant for opensocial specification.
    // http://www.opensocial.org/Technical-Resources/opensocial-spec-v09/REST-API.html
    var map = {};
    emit([doc.userId, doc.appId, doc.key], doc.value);
  }
}