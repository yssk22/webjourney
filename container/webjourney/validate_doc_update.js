function(newDoc, oldDoc, userCtx, secObj){
   var Validator = require('lib/validations/common');
   var v = new Validator(newDoc, oldDoc, userCtx, secObj);
   v.unchanged("type");

   var type = (saveDoc || newDoc)["type"];
   if( !type ){
      throw({forbidden: "type field must be specified."});
   }
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
}