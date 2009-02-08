function(doc){
  if( doc.class == "WjPage"){
    emit(doc.updated_at, doc);
  }
}
