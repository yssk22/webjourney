exports.validate = function(v){
   v.required("displayName");
   v.equals("_id", "p:" + v.userCtx.name );
   var attachments = v.newDoc._attachments;
   for(var i in attachments){
      var file = attachments[i];
      var content_type = file.content_type;
      if(!content_type.match(/^image\//)){
         log("Invalid file type");
         v.forbidden("Invalid file type.");
      }
   }
};