function filterInstances(list, joinkeys, include){
  var matched = [];
  for(var i=0; i<list.length; i++){
    var instance = values[i];
    if( instance._id ){
      if( include ){
        if( joinkeys.joinkeys[instance._id] ){
          matched.push(instance);
        }
      }else{
        if( !joinkeys.joinkeys[instance._id] ){
          matched.push(instance);
        }
      }
    }
  }
  return matched;
}
