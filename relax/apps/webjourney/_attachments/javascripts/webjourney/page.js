WebJourney = {};
WebJourney.Page = function(){
  this.initialize.apply(this, arguments);
};
WebJourney.Page.LOCATIONS = ["top", "bottom", "left", "right", "center"];

WebJourney.Page.prototype = {

  /**
   * Page object that manages gadget containers.
   * @constructor
   * @param document Object document retrieved from CouchDB
   */
  initialize : function(document, app){
    this._document = document;
    this._couchapp = app;
    this._initializeContainers();
  },

  /**
   * Initialize container object
   */
  _initializeContainers : function(){
    // reuse the shindig container implementation (IfrContainer);
    gadgets.container = new gadgets.IfrContainer();
    this._container = gadgets.container;
    // callback
    var self = this;
    var container = self._container;
    // clean up container & location
    container.view_    = "default";
    container.gadgets_ = {};
    var chromeIds  = [];
    for(var l in WebJourney.Page.LOCATIONS){
      var lkey = WebJourney.Page.LOCATIONS[l];
      var location  = self._getContainerElement(lkey);
      var gadgetData = self._document.gadgets[lkey];
      if( gadgetData instanceof Array && gadgetData.length > 0 ){
        // create and add gadget.Gadget instances on the each container
        var chromeHTML = "";
        for(var i in gadgetData ){
          var gadget = container.createGadget(self._getGadgetArguments(gadgetData[i]));
          gadget.setServerBase(self.getServerBase());
          gadget.secureToken = encodeURIComponent(self.getSecureToken());
          container.addGadget(gadget);
          var chromeId = "gadget-chrome-" + gadget.id;
          chromeIds.push(chromeId);
          chromeHTML += "<div id=\"" + chromeId + "\" class=\"gadget-chrome\"></div>";
        }
        // set the gadget chrome ids on the each container
        location.html(chromeHTML);
        location.css("display", "block");
      }else{
        location.html("");
        location.css("display", "none");
      }
    }
    self._adjustContainerElements();
    container.layoutManager.setGadgetChromeIds(chromeIds);
    container.renderGadgets();
    self._applyThemeClasses();
  },

  /**
   * Fetch the gadget data related with this page and refresh the page gadgets
   */
  _loadGadgetData : function(){
  },

  /**
   * Apply the jQuery UI theme classes to the rendered Gadgets
   */
  _applyThemeClasses : function(){
    $("div.gadget-chrome").addClass("ui-widget");
    $("div.gadget-chrome").addClass("ui-widget-content");
    $("div.gadget-chrome").addClass("ui-corner-all");
    $("div.gadget-chrome div.gadgets-gadget-title-bar").addClass("ui-state-default ui-widget-header ui-corner-all");
  },
  /**
   * Adjust the width/margin of container div block elements
   */
  _adjustContainerElements : function(){
    var left    = this._getContainerElement("left");
    var right   = this._getContainerElement("right");
    var center  = this._getContainerElement("center");
    var wrapper     = $("#wrapper");
    var wrapperMain = $("#wrapper-main");

    var lwidth = left.css("display")  == "block" ? left.outerWidth(true)  : 0;
    var rwidth = right.css("display") == "block" ? right.outerWidth(true) : 0;
    wrapper.css("margin-right",    (-1) * rwidth);
    wrapperMain.css("margin-left", (-1) * lwidth);
    center.css("margin-right", rwidth > 0 ? rwidth + 10 : 0);
    center.css("margin-left",  lwidth > 0 ? lwidth + 10 : 0);
  },

  _getContainerId : function(locationKey){
    return "#container-" + locationKey;
  },

  _getContainerElement : function(locationKey){
    return $(this._getContainerId(locationKey));
  },
  /**
   * Returns a hash passed to gadget.Container.createGadget function.
   */
  _getGadgetArguments : function(gadgetData){
    var specUrl;
    if( gadgetData.url.match(/^(http|https)\:\/\//)){
      specUrl = gadgetData.url;
    }else{
      // gadget host on the same database
      dbname = unescape(document.location.href).split('/')[3];
      specUrl = document.location.protocol + "//" + document.location.host +
        "/" + dbname + gadgetData.url;
    }

    return {
      specUrl: specUrl,
      title: gadgetData.title
    };
  },

  /**
   * Returns a server base URI:
   */
  getServerBase : function(){
    return "http://webjourney.local/opensocial/gadgets/";
  },

  /**
   * Returns a security token
   */
  getSecureToken : function(){
    return "john.doe:john.doe:appid:cont:url:0:default";
  }
};
