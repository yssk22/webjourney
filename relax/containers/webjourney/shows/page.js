function(doc, req) {
  // !code vendor/couchapp/template.js
  // !code vendor/couchapp/path.js
  // !code lib/helpers/securityToken.js

  // !code vendor/crayon/lib/escape.js
  // !code vendor/crayon/lib/template.js
  // !json templates.page
  var bindings = {
    request : req,
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
      return template(templates.page.header, bindings) +
        template(templates.page.gadgets, bindings) +
        template(templates.page.dialogs, bindings) +
        template(templates.page.footer, bindings);
    }catch(e){
      bindings["title"] = "Internal Server Error";
      return {
        code: 500,
        body: template(templates.page.header, bindings) +
          e.toString() +
          template(templates.page.footer, bindings)
      };
    }
  }else{
    // nothing found.
    bindings["title"] = "Not Found";
    return {
      code: 404,
      body : template(templates.page.header, bindings) +
        "<h1>Not Found</h1>" +
        template(templates.page.footer, bindings)
    };
  }
};