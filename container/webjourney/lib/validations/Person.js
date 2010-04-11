exports.validate = function(v){
   v.required("displayName");
   v.equals("_id", "p:" + v.userCtx.name );
};