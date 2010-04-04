function(doc, req){
   // !code vendor/couchapp/path.js

   var t = require('vendor/crayon/lib/template');
   var ddoc = this;

   // !code include/bindings.js
   bindings["page.title"] = "Login";
   return t.render(ddoc.templates.site.html.header, bindings) +
      t.render(ddoc.templates.pages.login, bindings) +
      t.render(ddoc.templates.site.html.footer, bindings);
}