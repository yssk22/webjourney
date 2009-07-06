/**
 * @fileoverview WebJourney Gadget Container (Page) implementation
 */
WebJourney.Page = WebJourney.Page || function(){
  this.initialize.apply(this, arguments);
};

/**
 * Location symbols
 */
WebJourney.Page.LOCATIONS = ["top", "bottom", "left", "right", "center"];
WebJourney.Page._GADGET_SORTABLE_OPTION =  {
  connectWith: ["div.container"],
  placeholder: "ui-state-highlight",
  handle     : "div.gadget-title-bar",
  scroll     : true,
  cursor     : "move",
  forcePlaceholderSize: true,
  cursorAt: { top: 20, left: 20 }
};

WebJourney.Page.prototype = {

  /**
   * Page object that manages gadget containers.
   * @constructor
   * @param document Object document retrieved from Gadget Database by CouchDB.
   * @param app CouchApp application context.
   */
  initialize : function(document, app){
    this._document = document;
    this._couchapp = app;
    this._editMode = false;
    this._chromeIdCounter = 0;
    this._changed  = false;
    this._app      = app;

    this._initializeGadgets();
    this.renderGadgets();
    this.refresh();
  },

  /**
   * Toggle edit mode. Edit mode enable users to layout gadgets, add/remove gadgets, modify title labels, ... so on.
   */
  toggleEditMode : function(){
    if( this._editMode ){
      this._editMode = false;
    }else{
      this._editMode = true;
    }
    this._initializeGadgets();
    this.renderGadgets();
    this.refresh();
  },

  /**
   * Set _changed value to val.
   */
  setChanged : function(val){
    this._changed = val;
  },

  save : function(){
    this._gatherBoundDataFromGadgetBlocks();
    this._app.db.saveDoc(this._document);
  },

  /**
   * Render the html documents on the current page.
   */
  renderGadgets : function(){
    var self = this;
    for(var l in WebJourney.Page.LOCATIONS){
      var lkey = WebJourney.Page.LOCATIONS[l];
      var location  = this.getContainerElement(lkey);
      location.html("");
      for(var i in this._gadgets[lkey]){
        var block = this._gadgets[lkey][i].createBlockObject();
        block.data("gadget_object", this._gadgets[lkey][i]); // binding gadget object to block
        block.appendTo(location);
      }
      if( this._editMode ){
        location.addClass("container-edit-mode");
      }else{
        location.removeClass("container-edit-mode");
      }
    }
    if( this._editMode ){
      // make sortable
      jQuery("div.container").sortable(jQuery.extend(WebJourney.Page._GADGET_SORTABLE_OPTION,
        {
          start  : function(e, ui){ jQuery(ui.helper).width("200px"); },
          stop   : function(e, ui){ jQuery(ui.helper).width("100%");  },
          update : function(e, ui){ self.setChanged(true);       }
        }));
    }


    this.adjustLayout();
  },

  /**
   * Refresh the page.
   */
  refresh : function(){
    for(var l in WebJourney.Page.LOCATIONS){
      var lkey = WebJourney.Page.LOCATIONS[l];
      var location  = this.getContainerElement(lkey);
      var html = "";
      for(var i in this._gadgets[lkey]){
        this._gadgets[lkey][i].refresh();
      }
    }
  },

  /**
   * Adjust the width/margin of div block elements for gadget containers.
   */
  adjustLayout : function(){
    var left    = this.getContainerElement("left");
    var right   = this.getContainerElement("right");
    var center  = this.getContainerElement("center");
    var wrapper     = jQuery("#wrapper");
    var wrapperMain = jQuery("#wrapper-main");

    var lwidth = left.css("display")  == "block" ? left.outerWidth(true)  : 0;
    var rwidth = right.css("display") == "block" ? right.outerWidth(true) : 0;
    wrapper.css("margin-right",    (-1) * rwidth);
    wrapperMain.css("margin-left", (-1) * lwidth);
    center.css("margin-right", rwidth > 0 ? rwidth + 10 : 0);
    center.css("margin-left",  lwidth > 0 ? lwidth + 10 : 0);
  },

  getContainerId : function(locationKey){
    return "#container-" + locationKey;
  },

  /**
   * Returns a jQuery Object matched with locationKey
   * @param locationKey {String} location key name, one of WebJourney.Page.LOCATIONS
   */
  getContainerElement : function(locationKey){
    return jQuery(this.getContainerId(locationKey));
  },

  /**
   * Returns a server base URI for iframe gadgets.
   */
  getServerBase : function(){
    return "http://webjourney.local/opensocial/gadgets/";
  },

  /**
   * Returns a security token for iframe gadgets.
   */
  getSecureToken : function(){
    return "john.doe:john.doe:appid:cont:url:0:default";
  },

  /**
   * (Private) Initialize gadget objects for display
   */
  _initializeGadgets : function(){
    this._gadgets = {};
    for(var l in WebJourney.Page.LOCATIONS){
      var lkey = WebJourney.Page.LOCATIONS[l];
      this._gadgets[lkey] = [];
      var gadgets = this._document.gadgets[lkey];
      if( gadgets instanceof Array && gadgets.length > 0){
        for(var i in gadgets){
          var gadget = new WebJourney.Gadget(this, gadgets[i]);
          this._gadgets[lkey][i] = gadget;
        }
      }
    }
  },

  /**
   * (Private) Gather this._document.gadgets data and this._gadgets data from currently rendered elements.
   */
  _gatherBoundDataFromGadgetBlocks : function(){
    var gadget_parameters = {};
    var gadget_objects    = {};
    for(var l in WebJourney.Page.LOCATIONS){
      var lkey = WebJourney.Page.LOCATIONS[l];
      var location  = this.getContainerElement(lkey);
      gadget_parameters[lkey] = [];
      gadget_objects[lkey]    = [];
      jQuery("div.gadget", location)
        .each(function(index){
                var block = jQuery(this);
                var gadget_object = block.data("gadget_object");
                gadget_objects[lkey].push(gadget_object);
                gadget_parameters[lkey].push(gadget_object.getParameter());
              });
    }
    this._document.gadgets = gadget_parameters;
    this._gadgets = gadget_objects;
  }

};
