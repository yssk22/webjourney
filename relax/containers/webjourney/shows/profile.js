function(doc, req) {
   // !code vendor/couchapp/path.js
   // !code lib/helpers/securityToken.js
   // !code lib/helpers/util.js
   // !code vendor/crayon/lib/escape.js
   // !code vendor/crayon/lib/template.js
   // !code vendor/crayon/lib/error.js
   // !code vendor/crayon/lib/form.js

   // !json models.profile
   // !json templates.site
   // !json templates.profile

   var bindings = {
      request : req,
      current_user : req.userCtx,
      assetPath : assetPath(),
      site: {
         title: "Profile",
         javascripts: [
            "profile.js"
         ]
      }
   };


   if(doc && doc.type == "Person"){
      bindings["profile"] = doc;
      return render(templates.site.header, bindings) +
         render(templates.profile.main, bindings) +
         render(templates.site.footer, bindings);
   }else if(req.docId){
      var userid = req.docId.split(":");
      var domain = userid[0], username = userid[1];
      if( domain == req.headers["Host"] || domain == req.headers["X-Forwarded-Host"] ){
         if( username == req.userCtx.name ){
            bindings["profile"] = models.profile;
            bindings["profile"]["_id"] = req.docId;
            return render(templates.site.header, bindings) +
               render(templates.profile.not_found, bindings) +
               render(templates.site.footer, bindings);
         }else{
            // TODO HTML rendering
            return render_error(FORBIDDEN);
         }
      }else{
         // TODO HTML rendering
         return render_error(NOT_FOUND);
      }
   }else{
      // TODO HTML rendering
      return render_error(NOT_FOUND);
   }
}