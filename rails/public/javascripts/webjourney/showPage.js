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
    var self = this;
    for(var l in collection){
      jQuery.each(collection[l], function(){
                    var widgetInstance = new WebJourney.WidgetInstance(self, this);
                    widgetInstance.setNowLoading({overlay:false});
                    widgetInstance.show();
                    self._registerWidgetInstance(widgetInstance);
                  });
    }
  },

  isEditable : function(){
    return this._editable;
  },

  setEditable : function(value){
    this._editable = value;
  },

  editable : function(){
    return this._editable == true;
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