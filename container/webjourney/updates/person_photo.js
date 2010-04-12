function(doc, req){
   if( doc.type == "Person" ){
      var filename = req.form.filename;
      if( doc._attachments[filename] ){
         var content_type = doc._attachments[filename].content_type;
         if(content_type.match(/^image\//)){
            doc.photo = [filename];
            return [doc, '{"ok": true}'];
         }
      }
   }
   // error case
   return [null, '{"error": "bad request"}'];
}