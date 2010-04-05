function(doc, req){
   // !code vendor/couchapp/path.js
   var e = require('lib/errors');
   var t = require('vendor/crayon/lib/template');
   var ddoc = this;

   // !code include/bindings.js
   bindings["page.title"] = "Top";
   log(bindings["page.stylesheets"]);
   if( doc ){
      return "doc found";
   }else{
      if( req.path.length == 6 ){
         // id specified but not found.
         var profile_id = req.path[req.path.length - 1];
         var expected = "profile:" + req.userCtx.name;
         if( profile_id == expected ){
            return t.render(ddoc.templates.site.html.header, bindings) +
               t.render(ddoc.templates.pages.top.no_profile, bindings) +
               t.render(ddoc.templates.site.html.footer, bindings);
         }else{
            return e.not_found(ddoc, bindings);
         }
      }else{
         // no id specified.
         return t.render(ddoc.templates.site.html.header, bindings) +
            t.render(ddoc.templates.pages.top.guest, bindings) +
            t.render(ddoc.templates.site.html.footer, bindings);
      }
   }
}