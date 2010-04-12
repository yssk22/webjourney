function uploadPhoto(){
   var form = $("form#uploader");
   var id = form.find("[name='_id']").val();
   var file = form.find("[name='_attachments']").val();
   if( !file || file.length == 0 ){
      alert("no file specified.");
      return false;
   }
   var uri = App.db.uri + $.couch.encodeDocId(id);
   form.ajaxSubmit({
      url: uri,
      dataType: "json",
      success: function(resp){
         if( resp.error ){
            alert(resp.reason);
            return;
         }else{
            var uri = ["", App.db.name, App.design.doc_id,
                       "_update/person_photo", $.couch.encodeDocId(id)].join("/");
            $.ajax({
               url: uri,
               type: "POST",
               data: "filename=" + encodeURIComponent(file),
               success: function(msg){
                  window.location.href = window.location.href;
               }
            });
         }

      }
   });
   return false;
}

$(function(){
   $("form#uploader").dialog({ autoOpen: false,
                               modal: true,
                               resizable: false,
                               title: "Upload your photo",
                               buttons: { "Upload": function(){
                                  uploadPhoto();
                               }},
                               width: 450
                             });
   $("div.photo div.upload a").click(function(){
      $("form#uploader").dialog("open");
   });
});


$.couch.app(function(app){
   app.docForm("#create_profile",{
      fields: ["type", "_id", "displayName", "aboutMe"],
      beforeSave: function(doc){
         log(doc);
      },
      success: function(){
         // reload
         window.location.href = window.location.href;
      }
   });
});
