var LoginPage = {
  /** Login **/
  onLoginSuccess : function(data){
    // TODO go back to the referrer page.
    window.location.href = data.my_page_url;
  },
  onLoginFailure : function(request){
    LoginPage._handleFormFailure(request);
  },

  /** Registration **/
  onRegisterSuccess : function(data){
    LoginPage._switchToSuccess(request);
  },
  onRegisterFailure : function(request){
    LoginPage._handleFormFailure(request);
  },

  /** Registration **/
  onActivationSuccess : function(data){
    LoginPage._switchToSuccess(data);
  },
  onActivationFailure : function(request){
    LoginPage._handleFormFailure(request);
  },

  /** Password Reset **/
  onResetPasswordSuccess : function(data){
    LoginPage._switchToSuccess(data);
  },
  onResetPasswordFailure : function(request){
    LoginPage._handleFormFailure(request);
  },
  onUpdatePasswordSuccess : function(data){
    LoginPage._switchToSuccess(data);
  },
  onUpdatePasswordFailure : function(request){
    LoginPage._handleFormFailure(request);
  },

  /** OpenID **/
  onOpenIdRegisterSuccess : function(data){
    // POST system/open_id/begin_authentication to retry login process with open id
    Page.getDom("open_id_login_form").submit();
  },
  onOpenIdRegisterFailure : function(request){
    LoginPage._handleFormFailure(request);
  },

  /** Common Handler **/
  _handleFormFailure : function(request){
    if(request.status === 400){
      var json = jQuery.parseJSON(request.responseText);
      var dom  = Page.getDom("form");
      dom.wjDisplayErrors(json);
    }
  },

  _switchToSuccess : function(data){
    Page.getDom("form").css("display", "none");
    Page.getDom("success").css("display", "block");
  }
};