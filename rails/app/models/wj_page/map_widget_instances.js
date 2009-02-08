function(doc) {
  if( doc.class == "WjPage") {
    var joinkeys =  {};
    if( doc.widgets ){
      for(var l in doc.widgets){
        for(var i in doc.widgets[l] ){
          joinkeys[doc.widgets[l][i].instance_id] = true;
        }
      }
    }
    emit([doc._id, 0], {joinkeys : joinkeys});
  }
  if( doc.class == "WjWidgetInstance") {
    emit([doc.wj_page_id, 1], doc);
  }
}
