function(newDoc, oldDoc, userCtx, secObj){
   var m = require('lib/validations/common');
   var v = new m.Validator(newDoc, oldDoc, userCtx, secObj);
   v.required("type");
   v.unchanged("type");
   /*
   // require type specific validator
   Validator = require('lib/validations/' + type);
   v = new Validator(newDoc, oldDoc, userCtx, secObj);

   if(!oldDoc){
      v.validateOnCreate();
   }else if(newDoc._deleted){
      v.validateOnDelete();
   }else {
      v.validateOnUpdate();
   }
   v.validate();
   */
}