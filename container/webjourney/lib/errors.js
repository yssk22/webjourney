var t = require('vendor/crayon/lib/template');
function not_found(ddoc, bindings){
   return {
      code : 404,
      body : t.render(ddoc.templates.site.html.header, bindings) +
         t.render(ddoc.templates.site.html.not_found, bindings) +
         t.render(ddoc.templates.site.html.footer, bindings)
   };
}

exports.not_found = not_found;