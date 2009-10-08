function(doc){
  if( doc.type == "Application" ){
    emit(doc.module_prefs._attrs.category || "Unknown", doc);
  }
}