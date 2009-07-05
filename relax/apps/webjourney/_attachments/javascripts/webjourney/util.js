/**
 * @fileoverview WebJourney Utility Functions implementation
 */

WebJourney.Util = WebJourney.Util || {};

WebJourney.Util.tag = function(tagname, params, content){
  var str = "<" + tagname;
  if(params){
    for(var key in params){
      str = str + " " + key + "=\"" + params[key] + "\"";
    }
  }
  str = str + ">";
  if(content){
    return str + content + "</" + tagname + ">";
  }else{
    return str + "</" + tagname + ">";
  }
};

WebJourney.Util.toQueryString = function(params){
  var str = "";
  for(var key in params){
    str = str + encodeURIComponent(key) + "=" + encodeURIComponent(params[key]) + "&";
  }
  return str;
};