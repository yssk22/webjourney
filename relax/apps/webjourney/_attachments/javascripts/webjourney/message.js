/**
 * @fileoverview WebJourney Gadget Container (Page) implementation
 */
WebJourney.Message = WebJourney.Message || function(){
  this.initialize.apply(this, arguments);
};

WebJourney.Message._SPAN_ICONS = {
  "highlight" : '<span class="ui-icon ui-icon-info" style="float: left; margin-right: 0.3em;"></span>',
  "error"     : '<span class="ui-icon ui-icon-error" style="float: left; margin-right: 0.3em;"></span>'
};

WebJourney.Message._ERROR_SPAN =


WebJourney.Message._TYPES = ["error", "highlight"];

WebJourney.Message.prototype = {
  initialize : function(selector){
    this._dom = $(selector);
    this._dom.attr("class", "ui-widget");
    for(var i in WebJourney.Message._TYPES){
      var t = WebJourney.Message._TYPES[i];
      var obj = jQuery("<div></div>");
      obj.attr("class", "ui-state-" + t + " ui-corner-all wj-message");
      obj.hide();
      this._dom.append(obj);
    }
  },

  _show : function(type, msg){
    $("div", this._dom).hide();
    var target = $("div.ui-state-" + type, this._dom);
    target.html(
      WebJourney.Message._SPAN_ICONS[type]
      + msg
    );
    this._dom.show();
    target.show();
    target.fadeOut(2500);
  }
};

for(var i in WebJourney.Message._TYPES){
  var type = WebJourney.Message._TYPES[i];
  WebJourney.Message.prototype[type] = function(msg){
    this._show(type, msg);
  };
};