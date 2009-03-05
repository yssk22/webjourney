WebJourney.UI.PageSettingsDialog = function(){
  this.initialize.apply(this, arguments);
};

WebJourney.UI.PageSettingsDialog.prototype = jQuery.extend(
{
  initialize : function(page, options){
    this._page = page;
    this._changed = false;
    this._options = jQuery.extend({}, options);
    this.build();
  },

  build : function(){
    var self = this;
    this._dom = jQuery(document.createElement("div"));
    this._dom.attr("title", "Page Settings");
    jQuery("body").append(this._dom);
    this._dom.load(jQuery.wjAbsoluteUrl("/javascripts/webjourney/ui/page_settings_dialog.template.html"),
      function(){
        self.bindObjectToField();
        self._dom.dialog({
          modal       : true,
          resizable   : false,
          dialogClass : "page_settings_dialog",
          autoOpen    : false,
          buttons: {
            OK     : function(btn, evt){
              self.bindFieldToObject();
              self._options.ok && self._options.ok(evt, self);
              self.close();
            },
            Cancel : function(btn, evt){
              self._options.cancel && self._options.cancel(evt, self);
              self.close();
            }
          }
        });
      });
  },

  open : function(){
    this._dom.dialog("open");
  },

  close : function(){
    this._dom.dialog("close");
  },

  setChanged : function(changed){
    this._changed = changed;
  },

  isChanged  : function(){
    return this._changed;
  },

  bindFieldToObject : function(){
    this._object.description   = jQuery("textarea[name='desctiption']", this._dom).val();
    this._object.copyright     = jQuery("input[name='copyright']", this._dom).val();
    this._object.robots_index  = jQuery("input[name='robots_index']:checked", this._dom).length == 1;
    this._object.robots_follow = jQuery("input[name='robots_follow']:checked", this._dom).length == 1;
    this._object.keywords      = jQuery.grep(jQuery.map(jQuery("input[name='keywords']").val().split(","),
      function(a){
        return $.trim(a);
      }), function(a){
        return a !== "";
      });
    this.setChanged(true);
    return true;
  },

  bindObjectToField : function(){
    jQuery("textarea[name='description']",   this._dom).val(this._page.description);
    jQuery("input[name='copyright']",        this._dom).val(this._page.description);
    jQuery("input[name='keywords']",         this._dom).val(this._page.robots_index  ? "1" : null);
    jQuery("input[name='robots_index']",     this._dom).val(this._page.robots_follow ? "1" : null);
    jQuery("input[name='robots_follow']",    this._dom).val(this._page.keywords);
  }
});