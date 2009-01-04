WebJourney.PageBase = function(){
  this.initialize.apply(this, arguments);
};
WebJourney.PageBase.prototype = {
  initialize : function(name){
    this._title = name
  },

  adjustGrid : function(){
    var lwidth = 0;
    var rwidth = 0;
    var page_width = $("div#widgets").width();
    var cwidth = 0;
    // compute center width based following to the widths of left and right
    var left    = $("div#left_container");
    var right   = $("div#right_container");
    var center  = $("div#center_container");
    var bottom  = $("div#bottom_container");
    var wrapper = $("div#wrapper");
    var main    = $("div#main");
    if( left  && left.css("display") == "block" ){ lwidth = left.outerWidth(true);  }
    if( right && right.css("display") == "block" ){ rwidth = right.outerWidth(true); }

    // update layout containers
    wrapper.css("margin-right", (-1) * rwidth);
    main.css("margin-left", (-1) * lwidth);
    center.css("margin-right", rwidth > 0 ? rwidth + 10 : 0);
    center.css("margin-left", lwidth > 0 ? lwidth + 10 : 0);

  },

  setAuthToken : function(token){ this._authToken = token; },
  getAuthToken : function(){ return this._authToken;  },
  getAuthTokenObject : function(){ return { authenticity_token: this.getAuthToken() } },

  setRootPath    : function(path){ this._rootPath = path ; },
  getRootPath    : function(){ return this._rootPath; },

  getAbsoluteUrl : function(path){
    if( this._rootPath.match(/\/$/) && path.match(/^\// )){
      return this._rootPath.substr(1, this._rootPath.length - 1) + path;
    }else{
      return this._rootPath + path;
    }
  },
  getAbsoluteURL : function(path){ return this.getAbsoluteURL(path); },

  setCurrentLoginName : function(current_login_name){
    this._currentLoginName = current_login_name;
  },
  getCurrentLoginName : function(){
    return this._currentLoginName;
  },
  alertUnknownError : function(){
    alert("Unknown error has occurred.\nPlease retry lator or contact the administrator.");
  }
};