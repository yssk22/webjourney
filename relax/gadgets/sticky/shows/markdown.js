function(doc, req){
  // !json couchapp
  // !json templates.markdown

  // !code vendor/couchapp/path.js
  // !code vendor/ejs/ejs_production.js
  // !code vendor/webjourney/util.js
  // !code vendor/webjourney/gadget.js
  if(gadget){
    return render(templates.markdown);
  }else{
    return {
      code: 404,
      body: "Not Found"
    };
  }
}
