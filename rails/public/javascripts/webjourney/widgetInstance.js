WebJourney.WidgetInstance = function(){
  this.initialize.apply(this, arguments);
};

WebJourney.WidgetInstance.prototype = {
  initialize : function(page, object){
    this._object = object;
    this._page = page;
  },

  getId : function(){
    return this._object._id;
  },

  getPage : function(){
    return this._page;
  },

  deploy : function(domId){
    var block = this._buildBlock();
    $(domId).append(block);
    var self = this;
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
    this.setNowLoading();
    this.load({action : "edit"},{
      complete: function(req, status){
        self.getDom("show_header").hide();
        self.getDom("edit_header").show();
        self.getDom("edit_footer").show();
        self.getDom("saving").css("display", "none");
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
    postData.push({name : "title",
                   value : this.getDom("edit_title").val() });
    this.getDom("saving").css("display", "inline");
    $.ajax({
      type : "POST",
      url : url,
      timeout : 6000,
      data : postData,
      success: function(data, textStatus){
        self.getDom("show_header").show();
        self.getDom("edit_header").hide();
        self.getDom("edit_footer").hide();
        self.getDom("title").text(self.getDom("edit_title").val());
        body.html(data);
      },
      error : function(request, textStatus, errorThrown){
        body.html(request.responseText);
      },
      complete : function(request, textStatus){
        self.getDom("saving").css("display", "none");
      }
    });
  },

  cancel : function(){
    var self = this;
    this.getDom("saving").css("display", "inline");
    this.load({action : "show"},{
      complete: function(req, status){
        self.getDom("show_header").show();
        self.getDom("edit_header").hide();
        self.getDom("edit_footer").hide();
        self.getDom("saving").css("display", "none");
      }
    });
  },

  setNowLoading : function(){
    var body = $("#" + this.getDomId("body"));
    body.html('<div class="content"><span class="with_inline_icon icon_now_loading"> Now loading ... </div>');
  },

  getPath : function(url_options){
    var path = this._page.getRootPath() + "widgets/" +
      this._object._id       + "/" +
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
      return this._object._id + "_" + suffix;
    }
    else{
      return this._object._id;
    }
  },
  getDom : function(suffix){
    return $("#" + this.getDomId(suffix));
  },

  _buildBlock : function(){
    var self = this;
    var block = $(document.createElement("div"));
    block.attr("id", this.getDomId());
    block.addClass("widget");

    // building body
    var body = $(document.createElement("div"));
    body.attr("id", this.getDomId("body"));
    body.addClass("body");

    block.append(this._buildShowHeader());
    block.append(this._buildEditHeader());
    block.append(body);
    block.append(this._buildEditFooter());
    return block;
  },

  _buildShowHeader : function(){
    var self = this;
    var header = this._createElement("div", "show_header");
    header.addClass("ui-dialog-titlebar");
    header.addClass("header");

    var title    = this._createElement("div", "title");
    title.addClass("ui-dialog-title");
    title.addClass("title");
    title.text(this._object.title);

    var buttons = $(document.createElement("span"));
    buttons.attr("id", this.getDomId("buttons"));
    buttons.addClass("buttons");
    if( this._page.isEditable() ){
      var edit_anchor = $(document.createElement("a"));
      //edit_anchor.addClass("edit");
      edit_anchor.addClass("ui-dialog-titlebar-close");
      edit_anchor.addClass("edit");
      edit_anchor.bind("click",function(e){ self.edit(); });
      buttons.prepend(edit_anchor);
    }

    header.prepend(buttons);
    header.prepend(title);
    return header;
  },

  _buildEditHeader : function(){
    var self = this;

    var header = this._createElement("div", "edit_header");
    header.addClass("ui-dialog-titlebar");
    header.addClass("header");

    var title    = this._createElement("input", "edit_title");
    title.addClass("ui-dialog-title");
    title.addClass("title");
    title.val(this._object.title);

    header.prepend(title);
    header.hide();
    return header;
  },

  _buildEditFooter : function(){
    var self = this;
    // building footer
    var footer = this._createElement("div", "edit_footer");
    footer.addClass("footer");

    var saving = this._createElement("span", "saving");
    saving.addClass("with_inline_icon");
    saving.addClass("icon_saving");


    var save = this._createElement("button", "save");
    save.text("Save");
    save.addClass("submit");
    save.bind("click", function(e){ self.update(); });
    var cancel = this._createElement("button", "cancel");
    cancel.attr("type", "button");
    cancel.text("Cancel");
    cancel.bind("click", function(e){ self.cancel(); });
    saving.css("display", "none");
    footer.append(saving);
    footer.append(save);
    footer.append(cancel);

    footer.hide();
    return footer;
  },

  _createElement : function(tag, suffix){
    var dom = $(document.createElement(tag));
    dom.attr("id", this.getDomId(suffix));
    return dom;
  }
};
