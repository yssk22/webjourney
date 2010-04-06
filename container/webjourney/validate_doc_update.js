function(newDoc, oldDoc, userCtx, secObj){
   var m = require('lib/validations/common');
   var v = new m.Validator(newDoc, oldDoc, userCtx, secObj);
   v.required("type");
   v.unchanged("type");

   var type = newDoc.type;
   if( this.lib.validations[type] == undefined ){
      throw({forbidden: "Unknown type '" + type + "'."});
   }
   var m1 = require('lib/validations/' + type);

   m1.validate && m1.validate(v);
   if(!oldDoc){
      m1.validateOnCraete && m1.validateOnCreate(v);
   }else if(newDoc._deleted){
      m1.validateOnDelete && m1.validateOnDelete(v);
   }else {
      m1.validateOnUpdate && m1.validateOnUpdate(v);
   }
}