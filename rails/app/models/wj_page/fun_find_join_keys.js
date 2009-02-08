function findJoinKeys(list){
  for(var i in list){
    if( list[i].joinkeys ){
      return list[i];
    }
  }
  return null;
}
