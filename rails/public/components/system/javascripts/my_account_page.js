var MyAccountPage = {
  /** Update **/
  onUpdateSuccess : function(data){
    Page.getDom("general").wjClearErrors();
  },
  onUpdateFailure : function(request){
    MyAccountPage._handleFormFailure(request, "general");
  },

  onUpdatePasswordSuccess : function(data){
    Page.getDom("password").wjClearErrors();
  },
  onUpdatePasswordFailure : function(request){
    MyAccountPage._handleFormFailure(request, "password");
  },

  /** Common Handler **/
  _handleFormFailure : function(request, form){
    if(request.status === 400){
      var json = jQuery.parseJSON(request.responseText);
      var dom  = Page.getDom(form);
      dom.wjDisplayErrors(json);
    }
  }
};