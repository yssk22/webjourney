function(doc){
  if( doc.class == "WjPage"){
    emit(doc.title, doc);
  }
}
