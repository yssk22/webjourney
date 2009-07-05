/**
 * @fileoverview WebJourney Gadget implementation
 */

WebJourney.Gadget = function(){
  this.initialize.apply(this, arguments);
};

WebJourney.Gadget._DEFAULT_TITLE = "Title";

WebJourney.Gadget.prototype = {
  /**
   * Gadget object that manages a gadget instance on the page
   * @constructor
   * @param page WebJourney.Page object whichi loads the gadget.
   * @param params gadget parameter in page object;
   */
  initialize : function(page, params){
    this._page = page;
    this._params = params;
  },

  /**
   * Returns the identifier.
   */
  getId : function(){
    return this._params.id;
  },

  /**
   * Returns the 'id' attriubute of the iframe tag
   */
  getIframeId : function(){
    return "gadget-body-ifr-" + this.getId();
  },

  /**
   * Returns the 'name' attriubute of the iframe tag
   */
  getIframeName : function(){
    return this.getIframeId();
  },

  /**
   * Returns the specification url.
   */
  getSpecUrl : function(){
    var url = this._params.url;
    if( url.match(/^(http|https)\:\/\//)){
      return url;
    }else{
      // gadget host on the same database
      dbname = unescape(document.location.href).split('/')[3];
      return document.location.protocol + "//" + document.location.host +
        "/" + dbname + url;
    }
  },

  /**
   * Returns the specification version.
   */
  getSpecVersion : function(){
    return this._params.version || "";
  },

  /**
   * Returns the secure token.
   */
  getSecureToken : function(){
    return this._params.secureToken || this._page.getSecureToken();
  },

  /**
   * Returns nocache parameter.
   */
  getNoCache : function(){
    return (this._params.noCache || 1);
  },

  /**
   * Returns the server base path of the gadget.
   */
  getServerBase : function(){
    return this._params.serverBase || this._page.getServerBase();
  },

  /**
   * Returns iframe width
   */
  getWidth : function(){
    return this._params.width || "";
  },

  /**
   * Returns iframe height
   */
  getHeight : function(){
    return this._params.height || "100px";
  },

  /**
   * Returns the gadget HTML string.
   */
  getContent : function(){
    var params = {
      "id": "gadget" + this.getId(),
      "class": "ui-widget ui-widget-content ui-corner-all gadget"
    };
    return WebJourney.Util.tag("div",
                               params,
                               this.getTitleBarContent() +
                               this.getBodyContent());

  },

  refresh : function(){
    document.getElementById(this.getIframeId()).src = this.getIframeUrl();
    // $("#" + this.getIframeId()).attr("src", this.getIframeUrl());
  },



  getTitleBarContent : function(){
    var params = {
      "id": "gadget-title-bar-" + this.getId(),
      "class": "ui-widget ui-state-default ui-widget-header ui-corner-all gadget-title-bar"
    };
    return WebJourney.Util.tag("div",
                               params,
                               this.getTitleBarLabelContent() +
                               this.getTitleBarButtonsContent()
                              );
  },

  getTitleBarLabelContent : function(){
    var params = {
      "id": "gadget-title-bar-label-" + this.getId(),
      "class": "gadget-title-bar-label"
    };
    return WebJourney.Util.tag("span",
                               params,
                               this._title ? this._title : "Title"
                              );
  },

  getTitleBarButtonsContent : function(){
    var params = {
      "id": "gadget-title-bar-buttons-" + this.getId(),
      "class": "gadget-title-bar-buttons"
    };
    return WebJourney.Util.tag("span",
                               params,
                               ""
                              );
  },

  getBodyContent : function(){
    var params = {
      "id": "gadget-body-" + this.getId(),
      "class": "ui-widget gadget-body"
    };
    return WebJourney.Util.tag("div",
                               params,
                               this.getBodyIframeContent()
                              );
  },

  getBodyIframeContent : function(){
    var params = {
      "id"          : this.getIframeId(),
      "class"       : "gadget-body-ifr",
      "name"        : this.getIframeName(),
      "frameborder" : "no",
      "scrolling"   : "no",
      "height"      : this.getHeight(),
      "width"       : this.getWidth()
    };
    return WebJourney.Util.tag("iframe",
                               params);
  },

  getIframeUrl : function(){
    // http://webjourney.local/opensocial/gadgets/ifr?container=default
    // &mid=0&nocache=1&country=ALL&lang=ALL&view=default
    // &parent=http%3A%2F%2Fwebjourney.local&st=john.doe%3Ajohn.doe%3Aappid%3Acont%3Aurl%3A0%3Adefault
    // &url=http%3A%2F%2Fwebjourney.local%2Fwebjourney-pages-default%2F_design%2Fwebjourney%2Fgadgets%2Fhelloworld.xml#rpctoken=569353463
    var params = {
      "container" : "default",
      "mid"       : this.getId(),
      "nocache"   : this.getNoCache(),
      "url"       : this.getSpecUrl(),
      "st"        : this.getSecureToken(),
      "country"   : "ALL",
      "lang"      : "ALL",
      "view"      : "default"
//      "v"         : this.getSpecVersion()
    };

    return this.getServerBase() + "ifr?" +
      WebJourney.Util.toQueryString(params);
  }
};