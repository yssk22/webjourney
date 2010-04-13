ProfileWidget = {
   root: $("#profile-widget"),
   loading : function(option){
      $("div.ui-widget-content", this.root).nowLoading(option);
   },
   edit : function(){
      $("a.edit_link", this.root).hide();
      $("div.show", this.root).hide();
      $("div.edit", this.root).show();
   },
   show : function(){
      $("a.edit_link", this.root).show();
      $("div.show", this.root).show();
      $("div.edit", this.root).hide();
   }
};

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

   $("#profile-widget a.edit_link").click(function(){
      ProfileWidget.edit();
   });
   $("#profile-widget button.cancel").click(function(){
      ProfileWidget.show();
   });
});

$.couch.app(function(app){
   app.docForm("#create_profile",{
      fields: ["type", "_id", "displayName", "aboutMe"],
      beforeSave: function(doc){},
      success: function(){
         // reload
         window.location.href = window.location.href;
      }
   });
   app.docForm("#edit_profile",{
      fields: ["_id", "displayName", "aboutMe"],
      beforeSave: function(doc){
         ProfileWidget.loading({message: "Updating..."});
         // merge current doc.
         app.db.openDoc(doc._id, {
            success: function(current_doc) {
               doc._rev = current_doc._rev;
               doc._attachments = current_doc._attachments;
               doc.photo = current_doc.photo;
               doc.type = current_doc.type;
            }
         }, {
            async: false
         });
         if( doc._rev == undefined ){
            throw("failed to fetch current revision.");
            ProfileWidget.loading("clear");
         }
      },
      success: function(resp, doc){
         ProfileWidget.loading("clear");
         $("div.vcard span.nickname").text(doc.displayName);
         $("#profile-widget div.show div.aboutMe").html(new Showdown.converter().makeHtml(doc.aboutMe));
         ProfileWidget.show();
      }
   });
});
