function(doc){
  if(doc.type == "Relationship"){
    for(var i in doc.tags){
      // key includes doc.to to be sorted.
      emit([doc.from, doc.tags[i], doc.to], null);
    }
  }
}
