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
   * Returns WebJourney.Page object where the gadget should be rendered.
   */
  getPage : function(){
    return this._page;
  },

  /**
   * Returns an object that should be an element in gadgets member in a page document.
   */
  getParameter : function(){
    return this._params;
  },

  /**
   * Returns the identifier.
   */
  getId : function(){
    return this._params.id;
  },

  /**
   * Returns the title
   */
  getTitle : function(){
    return this._params.title || "Title";
  },

  /**
   * Returns Gadget View
   */
  getView : function(){
    return this._params.view || "canvas";
  },

  /**
   * Returns the id attributes of the top level div tag.
   */
  getBlockId : function(){
    return "gadget-" + this.getId();
  },

  /**
   * Returns the jQuery object of the top level 'div' tag;
   */
  getBlockObject : function(){
    return jQuery(document.getElementById(this.getBlockId()));
  },

  /*:
   * Returns the id attributes of body block 'div' tag;
   */
  getBodyId : function(){
    return   "gadget-body-" + this.getId();
  },

  /*:
   * Returns the jQuery object of body block 'div' tag;
   */
  getBodyObject : function(){
    return jQuery(document.getElementById(this.getBodyId()));
  },


  /**
   * Returns the 'id' attriubute of the iframe tag
   */
  getIframeId : function(){
    return "gadget-body-ifr-" + this.getId();
  },

  /**
   * Returns the jQuery object of iframe tag;
   */
  getIframeObject : function(){
    return jQuery(document.getElementById(this.getIframeId()));
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
   * Returns the security token.
   */
  getSecurityToken : function(){
    return this._params.securityToken;
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
   * Returns the gadget jQuery object that is appendable to the page.
   */
  createBlockObject : function(){
    var block = jQuery("<div></div>");
    block.attr("id",    this.getBlockId());
    block.attr("class", "ui-widget ui-widget-content ui-corner-all gadget");
    return block.append(this._createTitleBarBlock()).append(this._createBodyBlock());
  },

  /**
   * Refresh the iframe content.
   */
  refresh : function(){
    this.getIframeObject().attr("src", this.getIframeUrl());
  },

  /**
   * Hide iframe content
   */
  minimize : function(){
    // DO NOT apply any effects. Effects will cause many iframe reloadings ...
    // this.getBodyObject().hide("blind");
    this.getBodyObject().hide();
  },
  /**
   * Show iframe content
   */
  revertMinimize : function(){
    // DO NOT apply any effects. Effects will cause many iframe reloadings ...
    // this.getBodyObject().show("blind");
    this.getBodyObject().show();
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
      "country"   : "ALL",
      "lang"      : "ALL",
      "view"      : this.getView()
//      "v"         : this.getSpecVersion()
    };

    if( this.getSecurityToken() ){
      params["st"] = this.getSecurityToken();
    }
    return this.getServerBase() + "ifr?" +
      WebJourney.Util.toQueryString(params);
  },

  _createTitleBarBlock : function(){
    var obj = jQuery("<div></div>");
    obj.attr("id", "gadget-title-bar-" + this.getId());
    obj.attr("class", "ui-widget ui-state-default ui-widget-header ui-corner-all gadget-title-bar");
    obj.append(this._createTitleBarButtons());
    obj.append(this._createTitleBarLabel());
    return obj;
  },


  _createTitleBarLabel : function(){
    var label = jQuery("<div></div>");
    label.attr("id",    "gadget-title-bar-label-" + this.getId());
    label.attr("class", "gadget-title-bar-label");

    var span = jQuery("<span></span>");
    span.attr("id", "gadget-title-bar-label-span-" + this.getId());
    span.text(this.getTitle());
    var input = jQuery("<input></input>");
    input.attr("id", "gadget-title-bar-label-input-" + this.getId());
    input.hide();
    return label.append(span).append(input);
  },

  _createTitleBarButtons : function(){
    var self = this;
    var buttons = jQuery("<ul></ul>");
    buttons.attr("id",    "gadget-title-bar-buttons-" + this.getId());
    buttons.attr("class", "ui-widget ui-helper-clearfix gadget-title-bar-buttons");

    var minimize = this._createTitleBarButton("ui-icon-minus");
    minimize.toggle(
      function(){
        $("span", this).removeClass("ui-icon-minus");
        $("span", this).addClass("ui-icon-plus");
        self.minimize();
      },
      function(){
        $("span", this).removeClass("ui-icon-plus");
        $("span", this).addClass("ui-icon-minus");
        self.revertMinimize();
      }
    );

    return buttons.append(
      minimize
    );
  },

  _createTitleBarButton : function(icon_name, callback){
    var item = jQuery("<li></li>");
    item.attr("class", "ui-state-default ui-corner-all");
    callback && item.bind("click", callback);
    item.hover(
      function(){ $(this).addClass("ui-state-hover");    },
      function(){ $(this).removeClass("ui-state-hover"); }
    );
    var icon = jQuery("<span></span>");
    icon.attr("class", "ui-icon " + icon_name);
    return item.append(icon);
  },

  _createBodyBlock : function(){
    var body = jQuery("<div></div>");
    body.attr("id",    this.getBodyId());
    body.attr("class", "ui-widget gadget-body");
    return body.append(this._createBodyIframe());
  },

  _createBodyIframe : function(){
    var iframe = jQuery("<iframe></iframe>");
    iframe.attr("id",  this.getIframeId());
    iframe.attr("class", "gadget-body-ifr");
    iframe.attr("name",  this.getIframeName());
    iframe.attr("frameborder", "no");
    iframe.attr("scrolling", "no");
    iframe.attr("height", this.getHeight());
    iframe.attr("width",  this.getWidth());
    return iframe;
  }

};