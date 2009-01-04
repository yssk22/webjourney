WebJourney.WjPage = function(){
  this.initialize.apply(this, arguments);
};
WebJourney.WjPage.prototype = jQuery.extend(new WebJourney.PageBase, {
  initialize : function(object, uri){
    if( object ){
      WebJourney.PageBase.prototype.initialize.apply(this, [object.title]);
    }
    this._object = object;
    this._uri    = uri;
  },

  getImagePath : function(component, widget){
    return this.getRootPath() + "components/" + component + "/images/" + widget + ".png";
  },

  getPagePath  : function(){
    return this.getRootPath() + "pages/" + this._object._id;
  }

});