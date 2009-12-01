function(doc, req) {
   // !code vendor/couchapp/path.js
   // !code lib/helpers/securityToken.js
   // !code vendor/crayon/lib/escape.js
   // !code vendor/crayon/lib/template.js

   // !json templates.page
   // !json templates.page.dialogs

   var bindings = {
      current_user : req.userCtx,
      assetPath : assetPath()
   };

   if( doc ){
      bindings["page"] = doc;
      try{
         // set the security token for each gadgets
         for(var location in doc.gadgets){
            log(location);
            for(var i in doc.gadgets[location]){
               log(i);
               var gadget = doc.gadgets[location][i];
               // TODO fix adhoc implementation to publish security tokens.
               var st = createSecurityToken(
                  doc.owner,             // owner
                  doc.owner,             // viewer
                  gadget.url,            // appId
                  "example.com",         // domainId
                  gadget.url,            // appUrl
                  doc._id                // moduleId
               );
               gadget["securityToken"] = st;
            }
         }
         doc._revisions = undefined;
         bindings["title"] = doc.title;
         return render(templates.page.header, bindings) +
            render(templates.page.gadgets, bindings) +
            '<div id="dialogs">' +
            render(templates.page.dialogs.login_dialog) +
            render(templates.page.dialogs.add_gadget_dialog) +
            '</div>' +
            render(templates.page.footer, bindings);
      }catch(e){
         bindings["title"] = "Internal Server Error";
         return {
            code: 500,
            body: render(templates.page.header, bindings) +
               e.toString() +
               render(templates.page.footer, bindings)
         };
      }
   }else{
      // nothing found.
      bindings["title"] = "Not Found";
      return {
         code: 404,
         body : render(templates.page.header, bindings) +
            "<h1>Not Found</h1>" +
            render(templates.page.footer, bindings)
      };
   }
};