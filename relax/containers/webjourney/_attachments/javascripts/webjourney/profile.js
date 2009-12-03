PROFILE_RULES = {
   "displayName-formatted": {
      required : true
   }
};

function alertError(status, error, reason){
   alert("[" + status + ":" + error + "] " + reason);
}

function onSubmitUpdateProfile(e){
   var f = jQuery("form#update_profile");
   e.preventDefault();
   var doc = f.serializeJson();
   if( f.valid() ){
      f.nowLoading({message: "Updating your profile ..."});
      Site.CouchApp.db.saveDoc(doc, {
         success: function(resp){
            alert("OK");
            f.find("input[name='_rev']").val(doc._rev);
            f.nowLoading("clear");
         },
         error: function(status, error, reason){
            alertError(status, error, reason);
            f.nowLoading("clear");
         }
      });
   }
   return false;
}

function onSubmitCreateProfile(e){
   var f = jQuery("form#create_profile");
   e.preventDefault();
   var doc = f.serializeJson();
   if( f.valid() ){
      f.nowLoading({message: "Submitting your profile ..."});
      Site.CouchApp.db.saveDoc(doc, {
         success: function(resp){
            f.nowLoading({message: "Building your page ..."});
            Site.go(Site.CouchApp.showPath("profile", doc._id));
         },
         error: function(status, error, reason){
            alertError(status, error, reason);
            f.nowLoading("clear");
         }
      });
   }
   return false;
}


$.CouchApp(function(app){
   var f = jQuery("form#create_profile");
   f.validate(PROFILE_RULES);
   f.submit(onSubmitCreateProfile);

   f = jQuery("form#update_profile");
   f.validate(PROFILE_RULES);
   f.submit(onSubmitUpdateProfile);
});