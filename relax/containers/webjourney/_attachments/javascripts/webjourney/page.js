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
    this._message  = new WebJourney.Message("#page-message");

    this._initializeGadgets();
    this.renderGadgets();
    this.refresh();

    log("[Page#initialize] " + JSON.stringify(this._document));
  },

  /**
   * Make the page mode to 'edit-mode'
   */
  edit : function(){
    this._editMode = true;
    this._changed  = false;
    this._initializeGadgets();
    this.renderGadgets();
    this.refresh();
  },

  /**
   * Make the page mode to 'show-mode'
   */
  cancelEdit : function(){
    if( this._changed ){
      if(!confirm("Discard changes?")){
        return; // cancel
      }
    }
    this._editMode = false;
    this._changed  = false;
    this._initializeGadgets();
    this.renderGadgets();
    this.refresh();
  },

  /**
   * Save the document to database
   */
  save : function(){
    log("[Page#save] --> " + JSON.stringify({"_id"  : this._document._id,
                                             "_rev" : this._document._rev}));
    var self = this;
    this._populateBoundDataFromGadgetBlocks();
    this._app.db.saveDoc(this._document, {
                           error   :function(status, error, reason){
                             log("[Page#save] <-- " + JSON.stringify({error: error, reason:reason}));
                             alert("The document could not be saved: " + reason);
                           },
                           success :function(resp){
                             log("[Page#save] <-- " + JSON.stringify(resp));
                             self._changed = false;
                             self._message.highlight("Updated successfully");
                           }
                         });
  },


  /**
   * Set _changed value to val.
   */
  setChanged : function(val){
    this._changed = val;
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
    // refresh the gadgets
    for(var l in WebJourney.Page.LOCATIONS){
      var lkey = WebJourney.Page.LOCATIONS[l];
      var location  = this.getContainerElement(lkey);
      var html = "";
      for(var i in this._gadgets[lkey]){
        this._gadgets[lkey][i].refresh();
      }
    }

    // edit-mode link and buttons
    if( this._editMode ){
      $(".show-mode").hide();
      $(".edit-mode").show();
    }else{
      $(".edit-mode").hide();
      $(".show-mode").show();
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

    if( this._gadgets["left"].length == 0 ){
      left.hide();
    }
    if( this._gadgets["right"].length == 0 ){
      right.hide();
    }

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
   * Returns a gadget rendering server base URI for iframe gadgets.
   */
  getServerBase : function(){
    // TODO make server base configurable (or automatically determined)
    return "http://webjourney.local/shindig/gadgets/";
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
   * (Private) Populate this._document.gadgets data and this._gadgets data from currently rendered elements.
   */
  _populateBoundDataFromGadgetBlocks : function(){
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
