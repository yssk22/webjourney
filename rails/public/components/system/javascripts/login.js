var PasswordUser = {
  onRegisterSuccess : function(request){
    PasswordUser._onSuccess(request);
  },

  onRegisterFailure : function(request){
    PasswordUser._onFailure(request);
  },

  onResetPasswordSuccess : function(request){
    PasswordUser._onSuccess(request);
  },

  onResetPasswordFailure : function(request){
    PasswordUser._onFailure(request);
  },

  onActivationSuccess : function(request){
    PasswordUser._onSuccess(request);
  },

  onActivationFailure : function(request){
    PasswordUser._onFailure(request);
  },

  /* General Handler for success request */
  _onSuccess : function(request){
    Page.getDom().find(".form-container").hide();
    Page.getDom().find(".success").show();
  },

  /* General Handler for failure request */
  _onFailure : function(request){
    if( 400 <= request.status < 500 ){
      var json = jQuery.parseJSON(request.responseText);
      var dom = Page.getDom().find(".form-container");
      dom.wjDisplayErrors('account', json.errors, {message : Page.getDom("errors")});
    }else{
      alert("Unexpected error has been detected. Contact administrator.");
    }
  }

};


