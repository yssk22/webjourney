var Validator = function(newDoc, oldDoc, userCtx, secObj){
   this.newDoc = newDoc;
   this.oldDoc = oldDoc;
   this.userCtx = userCtx;
   this.secObj = secObj;
};

Validator.prototype = {
   forbidden: function(message){
      throw({forbidden: message});
   },

   unauthorized: function(message){
      throw({unauthorized: message});
   },

   required : function(){
      for (var i=0; i < arguments.length; i++) {
         var field = arguments[i];
         var message = "The '"+field+"' field is required.";
         if (typeof this.newDoc[field] == "undefined"){
            this.forbidden(message);
         }
      };
   },

   unchanged : function(){
      for (var i=0; i < arguments.length; i++) {
         var field = arguments[i];
         var message = "The '"+field+"' field cannot be changed.";
         if (this.oldDoc && this.oldDoc[field] != this.newDoc[field]){
            this.forbidden(message);
         }
      };
   }
};

exports.Validator = Validator;