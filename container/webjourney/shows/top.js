function(doc, req){
   // !code vendor/couchapp/path.js
   var e = require('lib/errors');
   var t = require('vendor/crayon/lib/template');
   var ddoc = this;

   // !code include/bindings.js
   bindings["page.title"] = "Top";
   log(bindings["page.stylesheets"]);
   if( doc ){
      if( doc.type == "Person" ){
         bindings["page.title"] = doc._id.split(":")[1] + "'s home page";

         // set binding variables
         bindings["p._id"] = doc._id;
         bindings["p._rev"] = doc._rev;
         bindings["p.displayName"] = doc.displayName;
         if( doc.photo ){
            bindings["p.photo"] = ["", req.info.db_name, doc._id, doc.photo].join("/");
         }

         var expected = "p:" + req.userCtx.name;
         if( doc._id == expected ){
            return t.render(ddoc.templates.site.html.header, bindings) +
               t.render(ddoc.templates.pages.top.mine, bindings) +
               t.render(ddoc.templates.site.html.footer, bindings);
         }else{
            return t.render(ddoc.templates.site.html.header, bindings) +
               t.render(ddoc.templates.pages.top.other, bindings) +
               t.render(ddoc.templates.site.html.footer, bindings);
         }
      }else{
         return e.not_found(ddoc, bindings);
      }
   }else{
      if( req.path.length == 6 ){
         // id specified but not found.
         var p_id = req.path[req.path.length - 1];
         var expected = "p:" + req.userCtx.name;
         if( p_id == expected ){
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