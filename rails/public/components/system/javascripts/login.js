var PasswordUser = {
  onRegisterSuccess : function(request){
    Page.getDom().find(".form-container").hide();
    Page.getDom().find(".success").show();
  },

  onRegisterFailure : function(request){
    if(request.status === 400){
      var json = jQuery.parseJSON(request.responseText);
      var dom = Page.getDom().find(".form-container");
      dom.wjDisplayErrors('account', json.errors, {message : Page.getDom("errors")});
    }else{
      alert("Unexpected error has been detected. Contact administrator.");
    }
  },

  onResetPasswordSuccess : function(request){
    Page.getDom().find(".form-container").hide();
    Page.getDom().find(".success").show();
  },

  onResetPasswordFailure : function(request){
    if( 400 <= request.status < 500 ){
      var json = jQuery.parseJSON(request.responseText);
      var dom = Page.getDom().find(".form-container");
      dom.wjDisplayErrors('account', json.errors, {message : Page.getDom("errors")});
    }else{
      alert("Unexpected error has been detected. Contact administrator.");
    }
  }
};


