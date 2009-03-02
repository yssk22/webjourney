WebJourney.WidgetInstance = function(){
  this.initialize.apply(this, arguments);
};

WebJourney.WidgetInstance.prototype = {
  initialize : function(page, object){
    this._object = object;
    this._page = page;
  },

  getId : function(){
    return this._object.id;
  },

  getPage : function(){
    return this._page;
  },

  deploy : function(domId){
    this.setNowLoading();
    this.show();
  },

  load : function(url_options, callbacks){
    var url = this.getPath(url_options);
    var dom = $("#" + this.getDomId("body"));
    var body = $("#" + this.getDomId("body"));
    $.ajax({
      url : url,
      timeout : 6000,
      success: function(data, textStatus){
        body.html(data);
        if( callbacks.success ) { callbacks.success(data, textStatus); }
      },
      error : function(data, textStatus, errorThrown){
        if( textStatus == "timeout" ){
          body.html("<div class='content'><span class='icon_error with_inline_icon'>Connection Error(Timeout)</span></div>");
        }
        else{
          if(400 <= data.status && data.status < 500){
            body.html("<div class='content'><span class='icon_error with_inline_icon'>Connection Error(Client Refused)</span></div>");
          }else if( 500 <= data.status ){
            body.html("<div class='content'><span class='icon_error with_inline_icon'>Connection Error(Server Error)</span></div>");
          }else{
            body.html("<div class='content'><span class='icon_error with_inline_icon'>Connection Canceled</span></div>");
          }
        }
        if( callbacks.error ) {
          callbacks.error(data, textStatus);
        }
      },
      complete : function(request, textStatus){
        if( callbacks.complete ) { callbacks.complete(request, textStatus); }
      }
    });
  },

  show : function(){
    var self = this;
    this.load({action : "show"},{
      complete: function(req, status){
        self.getDom("show_header").show();
        self.getDom("edit_header").hide();
        self.getDom("edit_footer").hide();
      }
    });
  },


  edit : function(){
    var self = this;
    this.getDom().wjNowLoading();
    this.load({action : "edit"},{
      complete: function(req, status){
        self.getDom("show_header").hide();
        self.getDom("edit_header").show();
        self.getDom("edit_footer").show();
        self.getDom().wjClearOverlay();
      }
    });
  },

  update : function(){
    var self = this;
    if( this.beforeUpdate ){
      this.beforeUpdate();
    }

    var body = this.getDom("body");
    var url = this.getPath({ action : "update"});
    var postData = $("#" + this.getDomId("body") + " form").serializeArray();
    var newTitle = this.getDom("edit_title").val();
    postData.push({name : "title",
                   value : newTitle});
    this.getDom().wjNowLoading();
    $.ajax({
      type : "POST",
      url : url,
      timeout : 6000,
      data : postData,
      success: function(data, textStatus){
        self.getDom("show_header").show();
        self.getDom("edit_header").hide();
        self.getDom("edit_footer").hide();
        self.getDom("title").text(newTitle);
        body.html(data);
      },
      error : function(request, textStatus, errorThrown){
        body.html(request.responseText);
      },
      complete : function(request, textStatus){
        self.getDom().wjClearOverlay();
      }
    });
  },

  cancel : function(){
    var self = this;
    self.getDom().wjNowLoading();
    this.load({action : "show"},{
      complete: function(req, status){
        self.getDom("show_header").show();
        self.getDom("edit_header").hide();
        self.getDom("edit_footer").hide();
        self.getDom().wjClearOverlay();
      }
    });
  },

  setNowLoading : function(option){
    var body = jQuery("#" + this.getDomId("body")).wjNowLoading(option);
  },

  getPath : function(url_options){
    var path = this._page.getRootPath() + "widgets/" +
      this._object.id        + "/" +
      this._object.component + "/" +
      this._object.widget    + "/";
    if( url_options.action ){
      path = path + url_options.action;
    }
    else{
      path = path + "show";
    }
    if( url_options.params ){
      path = path + "?" + $.param(url_options.params);
    }
    return path;
  },

  getDomId : function(suffix){
    if( suffix ){
      return this._object.id + "_" + suffix;
    }
    else{
      return this._object.id;
    }
  },

  getDom : function(suffix){
    return $("#" + this.getDomId(suffix));
  }
};
