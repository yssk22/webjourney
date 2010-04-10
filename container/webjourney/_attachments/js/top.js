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
