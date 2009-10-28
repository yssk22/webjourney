var _MODULE_PREFS_ATTRS = ["title", "title_url", "description", "author", "author_email", "category"];
/**
 * Define the gadget variable
 */
var gadget = (function(){
                var req_path = req.path.join("/");
                var app_path = ([
                                 req.path[0],  // {db}
                                 req.path[1],  // _design
                                 req.path[2]   // {app}
                                ]).join("/");
                for(var i in couchapp.gadgets){
                  var gadget_path =  app_path + "/" +
                    couchapp.gadgets[i]["xml"];
                  if( req_path == gadget_path ){
                    return couchapp.gadgets[i];
                  }
                }
                return null;
              })();

/**
 * supplement module preferences from the couchapp definition.
 */
(function(){
   for(var i in _MODULE_PREFS_ATTRS){
     var attr = _MODULE_PREFS_ATTRS[i];
     if( !gadget[attr] ){
       gadget[attr] = couchapp[attr];
     }
   }
})();


function modulePrefs(features){
  var s = "<ModulePrefs";
   for(var i in _MODULE_PREFS_ATTRS){
     var attr = _MODULE_PREFS_ATTRS[i];
     if( gadget[attr] ){
       s = s + "\n" + attr + "='" + gadget[attr] + "'";
     }
   }
  s = s + ">";
  if( features && features.constructor.name == "Array" ){
    for(var i in features){
      s = s + "\n<Require feature='" + features[i] + "' />";
    }
  }
  return s + "\n</ModulePrefs>";
}

function require_js(path){
  var src = "http://" + req.headers.Host + assetPath() + "/" + path;
  return "<script src=\"" + src + "\"></script>";
}
function require_css(path){
  var src = "http://" + req.headers.Host + assetPath() + "/" + path;
  return "<link rel=\"stylesheet\" href=\"" + src + "\" />";
}

function app_data(key){
  return "<div id=\"app_data_" + key + "\"></div>";
}