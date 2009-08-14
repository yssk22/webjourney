function(keys, values, rereduce){
  // merging key/value pairs in values
  var merged = {};
  for(var i in values){
    var kvpairs = values[i];
    for(var key in kvpairs){
      merged[key] = kvpairs[key];
    }
  }
  return merged;
}