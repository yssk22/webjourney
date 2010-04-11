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

   loginRequired : function(){
      if(this.userCtx.name == '' || this.userCtx.name == null ||
         this.userCtx.name == undefined ){
         this.forbidden("login required.");
      }
   },

   roleRequired : function(){
      for (var i=0; i < arguments.length; i++) {
         var role = arguments[i];
         if( this.userCtx.roles.indexOf(role) < 0 ){
            this.forbidden('\'' + role + '\' role is required');
         }
      }
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
   },


   formatted : function(){
      var r = arguments[arguments.length - 1];
      for (var i=0; i < arguments.length-1; i++) {
         var field = arguments[i];
         var val = this.newDoc[field];
         var message = "The '"+field+"' field is invalid format.";
         if (!(this.newDoc[field] && this.newDoc[field].match(r))){
            this.forbidden(message);
         }
      }
   },

   equals : function(){
      var r = arguments[arguments.length - 1];
      for (var i=0; i < arguments.length-1; i++) {
         var field = arguments[i];
         var val = this.newDoc[field];
         var message = "The '"+field+"' field is invalid.";
         if (val != r){
            this.forbidden(message);
         }
      }
   }
};

exports.Validator = Validator;
