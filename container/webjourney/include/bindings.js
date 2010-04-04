// included in all show, list functions
var $ = require('vendor/crayon/lib/crayon');
var bindings = $.extend({}, ddoc.include.page);
bindings["assetPath"] = assetPath();
bindings["page.user.name"] = req.userCtx.name;
bindings["page.user.roles"] = req.userCtx.roles;
bindings["page.account_navigation"] = function(){
   if( req.userCtx.name ){
      return t.render(ddoc.templates.site.html.partial.loggedin, bindings);
   }else{
      return t.render(ddoc.templates.site.html.partial.nologin, bindings);
   }
};

(function(){
   var name = "js/" + req.path[4] + ".js";
   if( ddoc["_attachments"][name] ){
      bindings["page.javascripts"].push(name);
   }
   name = "css/" + req.path[4] + ".css";
   if( ddoc["_attachments"][name] ){
      bindings["page.stylesheets"].push(name);
   }
})();
