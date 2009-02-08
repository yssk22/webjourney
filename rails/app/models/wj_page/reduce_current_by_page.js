function(keys, values, rr){
  <%= WjPage::JS_FUN_FIND_JOIN_KEYS %>
  <%= WjPage::JS_FUN_FILTER_INSTANCES %>
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
