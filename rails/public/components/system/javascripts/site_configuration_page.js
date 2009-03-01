SiteConfigurationPage = {
  onPageDefaultUpdateSuccess : function(data){
    SiteConfigurationPage._handleFormSuccess(data);
  },
  onPageDefaultUpdateFailure : function(request){
    SiteConfigurationPage._handleFormFailure(request);
  },

  onSmtpUpdateSuccess: function(data){
    SiteConfigurationPage._handleFormSuccess(data);
  },

  onSmtpUpdateFailure: function(request){
    SiteConfigurationPage._handleFormFailure(request);
  },

  onAccountUpdateSuccess: function(data){
    SiteConfigurationPage._handleFormSuccess(data);
  },

  onAccountUpdateFailure: function(request){
    SiteConfigurationPage._handleFormFailure(request);
  },


  /** Common Handler **/
  _handleFormSuccess : function(data){
    var dom  = Page.getDom("form");
    dom.wjDisplayInfo();
    dom.wjClearErrors();
  },

  _handleFormFailure : function(request){
    dom.wjClearInfo();
    if(request.status === 400){
      var json = jQuery.parseJSON(request.responseText);
      var dom  = Page.getDom("form");
      dom.wjDisplayErrors(json);
    }
  }
};