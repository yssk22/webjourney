// Return a security token string.
function createSecurityToken(ownerId, viewerId, appId, domainId, appUrl, modId){
  var obj  = {
    "o" : ownerId,
    "v" : viewerId,
    "a" : appId,
    "d" : domainId,
    "u" : appUrl,
    "m" : modId,
    "t" : new Date().getTime()
  };
  return base64encode(encrypt(serialize(obj)));
}

//
// Extract (key, value) pairs and serialize them to "key1=val1&key2=val2&...""
// Each of pairs are encoded by encodeURIComponent().
//
function serialize(obj){
  var serialized = "";
  for(var key in obj){
    var val = obj[key];
    serialized = serialized + encodeURIComponent(key) + "=" + encodeURIComponent(val) + "&";
  }
  return serialized.substr(0, serialized.length - 1);
}

//
// Returns the base64 encoded string
//
function base64encode(tokenString){
  // TODO to be implemented.
  return tokenString;
}

//
// Returns the encrypted string.
//
function encrypt(tokenString){
  // TODO to be implemented.
  return tokenString;
}
