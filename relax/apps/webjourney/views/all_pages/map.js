function(doc){
  if( doc.type == "Page"){
    // remove gadgets metadata
    doc.gadgets = undefined;
    emit(doc.updated_at || null, doc);
  }
}