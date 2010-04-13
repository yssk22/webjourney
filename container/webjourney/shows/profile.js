function(doc, req){
   // !code vendor/couchapp/path.js
   var e = require('lib/errors');
   var t = require('vendor/crayon/lib/template');
   var ddoc = this;

   // !code include/bindings.js
   log(bindings['page.stylesheets']);
   if( doc ){
      if( doc.type == "Person" ){
         var u = require('vendor/crayon/lib/text');
         bindings["page.title"] = doc._id.split(":")[1] + "'s home page";
         // set binding variables
         bindings["p._id"] = doc._id;
         bindings["p._rev"] = doc._rev;
         bindings["p.displayName"] = doc.displayName;
         bindings["p.aboutMe"] = doc.aboutMe;
         bindings["p.aboutMe.formatted"] = u.markdown(doc.aboutMe);
         bindings["p.photo"] = doc.photo;
         if( doc.photo ){
            bindings["p.photo.formatted"] = ["", req.info.db_name, doc._id, doc.photo].join("/");
         }
         var expected = "p:" + req.userCtx.name;
         if( doc._id == expected ){
            bindings["page.javascripts"].push("../vendor/showdown/compressed/showdown.js");
            bindings["p._form"] = t.render(ddoc.templates.pages.profile._form, bindings);
            bindings["role.is_editor"] = true;
         }
         return t.render(ddoc.templates.site.html.header, bindings) +
            t.render(ddoc.templates.pages.profile.my, bindings) +
            t.render(ddoc.templates.site.html.footer, bindings);
      }
   }else{
      if( req.path.length == 6 ){
         // id specified but not found.
         var p_id = req.path[req.path.length - 1];
         var expected = "p:" + req.userCtx.name;
         if( p_id == expected ){
            bindings["p._id"] = expected;
            bindings["p._rev"] = undefined;
            bindings["p.displayName"] = req.userCtx.name;
            bindings["p.aboutMe"] = "Introduce yourself";
            bindings["p._form"] = t.render(ddoc.templates.pages.profile._form, bindings);
            return t.render(ddoc.templates.site.html.header, bindings) +
               t.render(ddoc.templates.pages.profile.create, bindings) +
               t.render(ddoc.templates.site.html.footer, bindings);
         }
      }
   }
   return e.not_found(ddoc, bindings);
}