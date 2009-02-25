UsersAndRolesPage = {
  loadUserList : function(starts_with){
    Page.getDom().find("table.alphabet tbody td a").removeClass("selected");
    Page.getDom().find("table.alphabet tbody td." + starts_with + " a").addClass("selected");
    var templatePath = Page.getAbsoluteUrl("/components/system/javascripts/templates/user_list.html");
    var dom = Page.getDom("user_list");
    UsersAndRolesPage._startListLoading(dom);
    jQuery.getJSON(UsersAndRolesPage.getUserListPath(starts_with),
                  function(users){
                    var jt = jQuery.createTemplateURL(templatePath,
                                                      null,
                                                      { filter_data: true, filter_params : true });
                    jt.setParam("Page", Page);
                    dom.setTemplate(jt);
                    dom.processTemplate(users);
                  });
  },

  getUserListPath : function(starts_with){
    return Page.getAbsoluteUrl("/components/system/users.json?starts_with=" + starts_with);
  },

  loadRoleList : function(){
    var templatePath = Page.getAbsoluteUrl("/components/system/javascripts/templates/role_list.html");
    var dom = Page.getDom("role_list");
    UsersAndRolesPage._startListLoading(dom);
    jQuery.getJSON(Page.getAbsoluteUrl("/components/system/roles.json"),
                  function(roles){
                    var jt = jQuery.createTemplateURL(templatePath,
                                                      null,
                                                      { filter_data: true, filter_params : true });
                    jt.setParam("Page", Page);
                    dom.setTemplate(jt);
                    dom.processTemplate(roles);
                  });
  },

  updateDefaultRoles : function(){
    var dom = Page.getDom();
    var disables = Page.getDom("role_list").find("input:checked").serializeArray() || "";
    UsersAndRolesPage._startListLoading(dom);
    jQuery.post(Page.getAbsoluteUrl("/components/system/roles/defaults.json"), disables, function(){
                  dom.wjClearOverlay();
                });
  },

  _startListLoading : function(placeholder){
    if( placeholder.find("table").length == 0 ){
      placeholder.wjNowLoading({overlay:false});
    }else{
      placeholder.wjNowLoading({overlay:true});
    }
  }

};