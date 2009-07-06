/**
 * @fileoverview WebJourney Utility Functions implementation
 */

WebJourney.Util = WebJourney.Util || {};

/**
 * Returns a html element string specified by tagname
 * @param tagname {String} a tag name.
 * @param params  {Object} key-value pairs applied to the attributes.
 * @param content {String} a inner html string.
 */
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