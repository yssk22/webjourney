exports.validate = function(v){
   v.required("displayName");
   v.equals("_id", "profile:" + v.userCtx.name );
};