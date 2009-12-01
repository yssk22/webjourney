function(doc, req){
   // !code vendor/couchapp/path.js
   // !code vendor/crayon/lib/escape.js
   // !code vendor/crayon/lib/template.js

   // !json templates.site
   // !json templates.login

   var bindings = {
      current_user : req.userCtx,
      assetPath : assetPath(),
      site: {
         title: "Sign Up",
         javascripts: [
            "login.js"
         ]
      }
   };
   return render(templates.site.header, bindings) +
      render(templates.login, bindings) +
      render(templates.site.footer, bindings);
}