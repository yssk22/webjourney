WebJourney.EditPage = function(){
  this.initialize.apply(this, arguments);
};
WebJourney.EditPage.prototype = jQuery.extend(new WebJourney.WjPage, {
  initialize : function(object, uri){
    WebJourney.WjPage.prototype.initialize.apply(this, [object, uri]);
  },

  addWidget: function(args){
    var block = this._buildWidgetInstanceBlock(args);
    var target = "#" + $("#location_of_widget_selections").val();
    block.css("display", "none");
    $(target).prepend(block);
    block.show("puff", {percent: 150}, 300);
    this.setChanged(true);
  },

  prepareDialogs : function(){
    var self = this;
    this._pageSettingsDialog = new WebJourney.Widgets.PageSettingsDialog(this._object, "#page_settings",
                                                                         { OK : function(){ self.setChanged(true); } });
    this._preparePermissionsDialog();
    this._prepareWidgetSelectionDialog();
  },

  prepareWidgets : function(){
    this._prepareWidgetsDD();
  },

  initWidgetInstances : function(collection){
    for(var location in collection){
      var instances = collection[location];
      for(var i in instances){
        var instance =instances[i];
        var target = "#" + location + "_container";
        var block = this._buildWidgetInstanceBlock(instance);
        block.css("display", "none");
        $(target).append(block);
        block.show("puff", {percent: 150}, 300);
      }
    }
  },

  save : function(){
    // update widgets
    this._object.widgets = this._collectWidgets();
    var data = $.extend(this.getAuthTokenObject(), {
      page    : this._object
    });
    var self = this;
    $("#page_saving").css("display", "inline");
    $.ajax({
      type : "POST",
      url : this._uri + "?_method=put",
      data: $.toJSON(data),
      dataType : "json",
      contentType: "application/json",
      success: function(newobject, status){
        self.updateFromServerResponse(newobject);
        self.setChanged(false);
      },
      error : function (request, textStatus, errorThrown) {
      },
      complete: function (request, textStatus) {
        $("#page_saving").css("display", "none");
      }
    });
  },

  back : function(){
    if(this._changed){
      if(confirm("Discard changes?")){
        window.location.href = this._uri;
      }
    }
    else{
      window.location.href = this._uri;
    }
  },

  hasChanged : function(){
    return this._changed;
  },

  setChanged : function(flag){
    this._changed = flag;
    $("#page_changed").css("display", flag ? "inline" : "none");
  },

  setSettingsDialogValues : function(btn, evt){
    this._object.description = $("#page_settings_description").val();
    this._object.copyright = $("#page_settings_copyright").val();
    this._object.robots_index = $("#page_settings_robots_index:checked").length == 1;
    this._object.robots_follow = $("#page_settings_robots_follow:checked").length == 1;
    this._object.keywords = $.grep($.map($("#page_settings_keywords").val().split(","),
      function(a){
        return $.trim(a);
      }), function(a){
        return a !== "";
      });
    this.setChanged(true);
    return true;
  },

  showPermissionsDialog : function(){
    jQuery("#page_permissions").dialog("open");
  },

  showSettingsDialog : function(){
    jQuery("#page_settings").dialog("open");
  },

  _preparePermissionsDialog : function(){
    jQuery("#page_permissions").dialog({
      modal: true,
      resizable: false,
      dialogClass: "page_permissions_dialog",
      autoOpen : false,
      buttons: {
        OK     : function(btn, evt){ $('#page_permissions').dialog("close"); },
        Cancel : function(btn, evt){ $('#page_permissions').dialog("close"); }
      }
    });
  },

  _prepareSettingsDialog : function(){
    jQuery("#page_settings").dialog({
      modal: true,
      resizable: false,
      dialogClass: "page_settings_dialog",
      autoOpen : false,
      buttons: {
        OK     : function(btn, evt){
          if( Page.setSettingsDialogValues() ){
            $('#page_settings').dialog("close");
          }
        },
        Cancel : function(btn, evt){ $('#page_settings').dialog("close"); }
      }
    });
    $("#page_settings_description").val(this._object.description);
    $("#page_settings_copyright").val(this._object.copyright);
    $("#page_settings_robots_index").val(this._object.robots_index   ? ["1"] : []);
    $("#page_settings_robots_follow").val(this._object.robots_follow ? ["1"] : []);
    $("#page_settings_keywords").val(this._object.keywords);
  },

  _prepareWidgetSelectionDialog : function(){
    var f = function(){
      var selected = $("#components_of_widget_selections option:selected").val();
      var div = "#widget_selections_" + selected;
      $("div.widget_list").css("display", "none");
      $(div).css("display", "block");
    };
    $("#components_of_widget_selections").change(f);
    f();
  },

  _prepareWidgetsDD : function(){
    var self = this;
    $("div.widget_container").sortable({
      containment: "#body",
      connectWith : ["div.widget_container"],
      placeholder: "widget_hover",
      handle: "div.header",
      scroll: true,
      cursor: "move",
      forcePlaceholderSize: true,
      cursorAt: { top: 20, left: 20 },
      start : function(e, ui){
        $(ui.helper).width("200px");
      },
      stop  : function(e, ui){
        $(ui.helper).width("100%");
      },
      update : function(e,ui){
        self.setChanged(true);
      }
    });
  },

  // collect the widgets data.
  _collectWidgets : function(){
    return {
      top    : this._collectWidgetsByLocation("top"),
      left   : this._collectWidgetsByLocation("left"),
      center : this._collectWidgetsByLocation("center"),
      right  : this._collectWidgetsByLocation("right"),
      bottom : this._collectWidgetsByLocation("bottom")
    };
  },

  // collect the widgets data on each locations.
  _collectWidgetsByLocation : function(location){
   return $.map($("#" + location + "_container div.widget"), function(n, i){
     return $(n).data("widget");
    });
  },

  // build div block for widget instance
  _buildWidgetInstanceBlock : function(args){
    var self = this;
    var block = $(document.createElement("div"));
    if( args._id ){
      block.attr("id", args._id);
    }
    block.addClass("widget");

    // buildint title
    var header = $(document.createElement("div"));
    header.addClass("ui-dialog-titlebar");
    header.addClass("header");

    var title  = $(document.createElement("span"));
    title.addClass("ui-dialog-title");
    title.addClass("title");
    title.text(args.title);

    var buttons = $(document.createElement("span"));
    buttons.addClass("buttons");
    var garbage_anchor = $(document.createElement("a"));
    garbage_anchor.addClass("ui-dialog-titlebar-close");
    garbage_anchor.addClass("delete");
    garbage_anchor.bind("click", function(e){
      var parent = $(this).parent().parents(".widget");
      parent.hide("puff", {percent: 50}, 300, function(e){
        parent.remove();
      });
      self.setChanged(true);
    });
    buttons.prepend(garbage_anchor);

    header.prepend(buttons);
    header.prepend(title);

    // building body
    var body = $(document.createElement("div"));
    body.addClass("body");
    body.html("<img src='" + this.getImagePath(args.component, args.widget) + "' />");

    // building data
    var data = {
      component : args.component,
      widget : args.widget
    };
    if( args.id ){
      data.instance_id = args.id;
    }

    // add to container
    block.append(header);
    block.append(body);
    block.data("widget", data);
    return block;
  },

  updateFromServerResponse : function(newobject){
    this._object = newobject;
    // update widget block
    for(var l in this._object.widgets){
      $("#" + l + "_container div.widget").each(function(index){
        $(this).data("widget").instance_id = newobject.widgets[l][index].instance_id;
      });
    }
  }

});
