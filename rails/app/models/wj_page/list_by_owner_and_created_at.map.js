function(doc) {
  if(doc.class == "WjPage"){
    emit([doc.owner_login_name, doc.created_at], doc);
  }
}
