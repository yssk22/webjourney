function(keys, values, rr){
  <%= JS_FIND_JOIN_KEYS %>
  <%= JS_FILTER_INSTANCES %>
  if( values.length > 0 ){
    var joinkeys = findJoinKeys(values);
    if( joinkeys ){
      var matched = filterInstances(values, joinkeys, true);
      matched.unshift(joinkeys);
      return matched;
    }
    else{
      return values;
    }
  }
  else{
     return [];
  }
}
