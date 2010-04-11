exports.validate = function(v){
   v.loginRequired();
   v.required("userId");
   v.equals("userId", v.userCtx.name);
   v.required("postedTime");
};

exports.validateOnCreate = function(v){
   v.formatted("_id", /[a-zA-Z0-9]{32}/);
};