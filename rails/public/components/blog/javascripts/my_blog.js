var MyBlog = {
  makeDialogs : function(){
    var dialogOption = {
      autoOpen : false,
      modal : true,
      resizable: false,
      height: 340,
      width: 640
    };
    dialogOption.title = "Create A New Blog";
    Page.getDom("create_blog_setting_form_dialog").dialog(dialogOption);
    dialogOption.title = "Update Blog";
    Page.getDom("update_blog_setting_form_dialog").dialog(dialogOption);
  },

  loadBlogSettings : function(){
    var dom = Page.getDom("blog_settings_table");
    dom.wjNowLoading();
    jQuery.getJSON(Page.getAbsoluteUrl("/components/blog/settings.json?for=" + Page.getCurrentLoginName()),
                                       function(settings){
                                         MyBlog.renderTable(settings);
                                       });
  },

  renderTable : function(settings){
    //alert(data.length);
    var dom = Page.getDom("blog_settings_table");
    var jt = jQuery.createTemplateURL(Page.getAbsoluteUrl("/components/blog/javascripts/blog_settings_table.template.html"),
      null,
      {filter_data: false, filter_params : false});
    jt.setParam("Page", Page);
    dom.setTemplate(jt);
    dom.processTemplate(settings);
  },

  openCreateBlogSettingForm : function(){
    Page.getDom("create_blog_setting_form_dialog").dialog("open");
  },

  openUpdateBlogSettingForm : function(id){
    Page.getDom("update_blog_setting_form_dialog").dialog("open");
    var dom = Page.getDom("update_blog_setting_form");
    var uri = Page.getAbsoluteUrl("/components/blog/settings/" + id + "/edit");
    var form = Page.getDom("update_blog_setting_form_dialog").find("form:first");
    var submit = Page.getDom("update_blog_setting_form_submit");
    submit.wjDisableSubmit({submitting: false});
    // load form contents from server.
    dom.wjLoad(uri, null, function(){
      submit.wjEnableSubmit();
      // clear events
      form.attr("onsubmit", null);
      form.unbind("submit");
      form.one("submit", function(){
        jQuery.ajax({
          beforeSend : function(request){ submit.wjDisableSubmit(); },
          complete   : function(request){ submit.wjEnableSubmit();  },
          success    : function(request){ MyBlog.onUpdateBlogSettingSuccess(); },
          failure    : function(request){ MyBlog.onUpdateBlogSettingFailure(); },
          data       : jQuery.param($(this).serializeArray()) + '&amp;authenticity_token=' + encodeURIComponent(Page.getAuthToken()),
          dataType   : 'script',
          type       : 'put',
          url        :  Page.getAbsoluteUrl("/components/blog/settings/" + id + ".json")
        });
        return false;
      });
    });
  },

  deleteBlogSetting : function(id){
    if(confirm("Are you sure?")){
        jQuery.ajax({
          beforeSend : function(request){  },
          success    : function(request){ MyBlog.onDeleteBlogSettingSuccess(); },
          failure    : function(request){ MyBlog.onDeleteBlogSettingFailure(); },
          dataType   : 'script',
          type       : 'delete',
          url        :  Page.getAbsoluteUrl("/components/blog/settings/" + id + ".json" +
                                            "?authenticity_token=" + encodeURIComponent(Page.getAuthToken()))
        });
    }
  },

  onCreateBlogSettingSuccess : function(){
    MyBlog.loadBlogSettings();
    Page.getDom("create_blog_setting_form_dialog").dialog("close");
  },

  onCreateBlogSettingFailure : function(){
  },

  onUpdateBlogSettingSuccess : function(){
    MyBlog.loadBlogSettings();
    Page.getDom("update_blog_setting_form_dialog").dialog("close");
  },

  onUpdateBlogSettingFailure : function(){
  },

  onDeleteBlogSettingSuccess : function(){
    MyBlog.loadBlogSettings();
  },

  onDeleteBlogSettingFailure : function(){
  }
};

var ManageEntry = {
  setBlogSettingId : function(val){ this._blog_setting_id = val; },
  getBlogSettingId : function(){ return this._blog_setting_id; },

  switchContainer : function(to){
    var containers = [
      "content_container",
      "create_blog_entry_form_container",
      "update_blog_entry_form_container"
      ];
    jQuery.each(containers, function(){
      var dom = Page.getDom(this);
      if( this.toString() === to ){
        dom.show();
      }else{
        dom.hide();
      }
    });
  },

  loadBlogEntries : function(direction){
    var setting_id = ManageEntry.getBlogSettingId();
    var url = "/components/blog/settings/" + setting_id + "/entries.json";
    if( this._expectedOffset === undefined){
      this._expectedOffset = 0;
    }

    switch(direction){
    case "reload":
      if( this._requestUrlCache ){ url = this._requestUrlCache; }
      break;
    case "next":
      if( this._entriesCache.next === null ||
          this._entriesCache.next.expected_offset < 0 ){
        // STOP!!
        return;
      }else{
        url = url + "?" + jQuery.wjParam(this._entriesCache.next);
      }
      break;
    case "previous":
      if( this._entriesCache.previous === null ||
          this._entriesCache.previous.expected_offset < 0 ){
        // STOP!!
        return;
      }else{
        url = url + "?" + jQuery.wjParam(this._entriesCache.previous);
      }
      break;
    default:
      break;
    }
    this._requestUrlCache = url;

    var dom = Page.getDom("blog_entries_table");
    dom.wjNowLoading();
    jQuery.getJSON(Page.getAbsoluteUrl(url),
                                       function(entries){
                                         ManageEntry._entriesCache = entries;
                                         ManageEntry.renderTable(entries);
                                       });
  },

  renderTable : function(entries){
    var page = Page.getDom();
    var dom = Page.getDom("blog_entries_table");
    var jt = jQuery.createTemplateURL(Page.getAbsoluteUrl("/components/blog/javascripts/blog_entries_table.template.html"),
      null,
      {filter_data: false, filter_params : false});
    jt.setParam("Page", Page);
    jQuery.jTemplatesDebugMode(true);
    dom.setTemplate(jt);
    dom.processTemplate(entries);
    // next, previous
    if( entries.previous === null ||
        entries.previous.expected_offset < 0){
      page.find("a.blog_entry_previous").addClass("disabled");
    }else{
      page.find("a.blog_entry_previous").removeClass("disabled");
    }
    if( entries.next === null ||
        entries.next.expected_offset < 0 ){
      page.find("a.blog_entry_next").addClass("disabled");
    }else{
      page.find("a.blog_entry_next").removeClass("disabled");
    }
  },

  editBlogEntry : function(id){
    var container = Page.getDom("create_blog_entry_form_container");
    var editorURL = Page.getAbsoluteUrl("/components/blog/settings/" + ManageEntry.getBlogSettingId() + "/entries/" + id + "/edit");
    var putUrl    = Page.getAbsoluteUrl("/components/blog/settings/" + ManageEntry.getBlogSettingId() + "/entries/" + id + ".json");
    var form      = Page.getDom("update_blog_entry_form_container").find("form:first");
    var submit    = Page.getDom("update_blog_entry_form_submit");
    submit.wjDisableSubmit({submitting: false});
    Page.getDom("update_blog_entry_form").wjLoad(editorURL, null, function(){
      submit.wjEnableSubmit();
      ManageEntry.initializeUpdateBlogEntryEditor();
      // clear events
      form.attr("onsubmit", null);
      form.unbind("submit");
      form.one("submit", function(){
        jQuery.ajax({
          beforeSend : function(request){ submit.wjDisableSubmit(); },
          complete   : function(request){ submit.wjEnableSubmit();  },
          success    : function(request){ ManageEntry.onUpdateBlogEntrySuccess(); },
          failure    : function(request){ ManageEntry.onUpdateBlogEntryFailure(); },
          data       : jQuery.param($(this).serializeArray()) + '&amp;authenticity_token=' + encodeURIComponent(Page.getAuthToken()),
          dataType   : 'script',
          type       : 'put',
          url        : putUrl
        });
        return false;
      });
    });
    ManageEntry.switchContainer("update_blog_entry_form_container");
  },

  deleteBlogEntry : function(id){
    if(confirm("Are you sure?")){
      var deleteUrl    = Page.getAbsoluteUrl("/components/blog/settings/" + ManageEntry.getBlogSettingId() + "/entries/" + id + ".json");
      var dom = Page.getDom("blog_entries_table");
      dom.wjNowLoading();
      jQuery.ajax({
        beforeSend : function(request){  },
        success    : function(request){ ManageEntry.onDeleteBlogEntrySuccess(); },
        failure    : function(request){ ManageEntry.onDeleteBlogEntryFailure(); },
        dataType   : 'script',
        type       : 'delete',
        url        :  deleteUrl +
                      "?authenticity_token=" + encodeURIComponent(Page.getAuthToken())
        });
    }
  },

  onCreateBlogEntrySuccess : function(){
    ManageEntry.switchContainer('content_container');
    Page.getDom("create_blog_entry_form").wjLoad(
      "/components/blog/settings/" + ManageEntry.getBlogSettingId() + "/entries/new", null,
      function(){ ManageEntry.initializeCreateBlogEntryEditor(); }
    );
    ManageEntry.loadBlogEntries();
  },

  onUpdateBlogEntrySuccess : function(){
    ManageEntry.loadBlogEntries("reload");
    ManageEntry.switchContainer("content_container");
  },

  onUpdateBlogEntryFailure : function(){
  },

  onDeleteBlogEntrySuccess : function(){
    ManageEntry.loadBlogEntries("reload");
  },

  onDeleteBlogEntryFailure : function(){
  },

  initializeCreateBlogEntryEditor : function(){
    var container = Page.getDom("create_blog_entry_form_container");
    var textarea  = container.find("div.form-container textarea:first");
    var input_tag_list = container.find("input[name='entry[tag_list]']");
    ManageEntry.initializeBlogEntryEditor(textarea, "#" + Page.getDomId("create_blog_entry_form_submit"));
    ManageEntry.initializeAutoComplete(input_tag_list);
    ManageEntry.updateCreateBlogEntryLink();
  },

  updateCreateBlogEntryLink : function(){
    var container = Page.getDom("create_blog_entry_form_container");
    var input_link     = container.find("input[name='entry[link]']");
    var iframe = container.find("div.blog_entry_link_frame iframe");
    if( input_link.val().match(/^http:\/\//) ){
      iframe.show();
      iframe.attr("src", input_link.val());
    }else{
      iframe.hide();
    }
  },

  initializeUpdateBlogEntryEditor : function(){
    var container = Page.getDom("update_blog_entry_form_container");
    var textarea  = container.find("div.form-container textarea:first");
    var input_tag_list = container.find("input[name='entry[tag_list]']");
    ManageEntry.initializeBlogEntryEditor(textarea, "#" + Page.getDomId("update_blog_entry_form_submit"));
    ManageEntry.initializeAutoComplete(input_tag_list);
  },

  initializeBlogEntryEditor : function(textarea, selector){
    textarea.wymeditor({
      updateSelector : selector,
      updateEvent : "focus",
      stylesheet: Page.getAbsoluteUrl('/components/blog/stylesheets/entry_editor.css'),
      boxHtml:   "<div class='wym_box'>" +
        "<div class='wym_area_top'>" +
        WYMeditor.TOOLS +
        "</div>" +
        "<div class='wym_area_left'></div>" +
        "<div class='wym_area_right'>" +
        WYMeditor.CONTAINERS +
        WYMeditor.CLASSES +
        "</div>" +
        "<div class='wym_area_main'>" +
        WYMeditor.HTML +
        WYMeditor.IFRAME +
        WYMeditor.STATUS +
        "</div>" +
        "<div class='wym_area_bottom'>" +
        "</div>" +
        "</div>",
      postInit : function(wym){
      }
    });
  },

  initializeAutoComplete : function(input_tag_list){
    var tags_url = Page.getAbsoluteUrl("/components/blog/settings/" + ManageEntry.getBlogSettingId() + "/tags.txt");
    input_tag_list.autocomplete(tags_url, {
     multiple: true,
     cacheLength : 1,
     formatItem : function(row, i, total){
        var array = row[0].split(",");
        var tag = "<div class='ac_tag_list'>" + h(array[0]) + "</div>";
        var num = "<div class='ac_tag_count'>" + array[1] + "</div>";
        return tag + num;
     },
     formatMatch : function(row, i, total){
        return row[0].split(",")[0];
     },
     formatResult: function(row, i, total) {
        return row[0].split(",")[0];
     }
   });
  }
};