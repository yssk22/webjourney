function(doc, req) {
  // !json templates.page
  // !code vendor/couchapp/template.js
  // !code vendor/couchapp/path.js
  // !code lib/helpers/securityToken.js

  if( doc ){
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
            doc.owner,            // viewer
            gadget.url,            // appId
            "example.com",         // domainId
            gadget.url,            // appUrl
            doc._id                // moduleId
          );
          gadget["securityToken"] = st;
        }
      }
      doc._revisions = undefined;
      var html = template(templates.page, {
                            page : doc,
                            assetPath: assetPath()
                          });
      return {body:html};
    }catch(e){
      return {body: e.toString() };
    }
  }else{
    // nothing found.
    return {
      code: 404,
      body : "Not Found"
    };
  }
};