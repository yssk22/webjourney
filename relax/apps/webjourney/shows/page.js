function(doc, req) {
  // !json templates.page
  // !code vendor/couchapp/template.js
  // !code vendor/couchapp/path.js
  if( doc ){
    try{
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