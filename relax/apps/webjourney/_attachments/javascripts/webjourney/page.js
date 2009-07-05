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
  },

  /**
   * Render the html documents on the current page.
   */
  renderGadgets : function(){
    for(var l in WebJourney.Page.LOCATIONS){
      var lkey = WebJourney.Page.LOCATIONS[l];
      var location  = this.getContainerElement(lkey);
      var html = "";
      for(var i in this._gadgets[lkey]){
        html += this._gadgets[lkey][i].getContent();
      }
      location.html(html);
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
    var wrapper     = $("#wrapper");
    var wrapperMain = $("#wrapper-main");

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
    return $(this.getContainerId(locationKey));
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
  }

};
