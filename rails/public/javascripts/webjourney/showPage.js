WebJourney.ShowPage = function(){
  this.initialize.apply(this, arguments);
};
WebJourney.ShowPage.prototype = jQuery.extend(new WebJourney.WjPage, {
  initialize : function(object, uri){
    WebJourney.WjPage.prototype.initialize.apply(this, [object, uri]);
    this._widgetInstances = {};
  },

  getId : function(){
    return this._object._id;
  },

  getWidgetInstance : function(id){
    return this._widgetInstances[id];
  },

  prepareDialogs : function(){
  },

  initWidgetInstances : function(collection){
    for(var l in this._object.widgets){
      for(var i in this._object.widgets[l]){
        var pointer = this._object.widgets[l][i];
        var instance_args = collection[pointer.instance_id];
        if( instance_args ){
          var widgetInstance = new WebJourney.WidgetInstance(this, instance_args);
          widgetInstance.setNowLoading();
          widgetInstance.show();
          this._registerWidgetInstance(widgetInstance);
        }
      }
    }
  },

  isEditable : function(){
    return this._editable;
  },

  setEditable : function(value){
    this._editable = value;
  },

  createNew : function(){
    $("#new_page_form").submit();
  },

  destroy : function(){
    if(confirm("Are you sure?")){
      var self = this;
      jQuery("#page_deleting").css("display", "inline");
      jQuery.ajax({
        type : "POST",
        url : this._uri + "?_method=delete&authenticity_token=" + this.getAuthToken(),
        success: function(){
          window.location.href = self.getRootPath();
        },
        error : function(request, textStatus, errorThrown){
          self.alertUnknownError();
        },
        complete: function (request, textStatus) {
          jQuery("#page_deleting").css("display", "none");
        }
      });
    }else{
      alert("Canceled.");
    }
  },

  _registerWidgetInstance : function(instance){
    this._widgetInstances[instance.getId()] = instance;
  }

});