if(!Blog){
  var Blog = {};
}
if(!Blog.EntryLoader){
  Blog.EntryLoader = function(){
    this.initialize.apply(this, arguments);
  };
  Blog.EntryLoader.prototype = {
    initialize : function(target, option){
      var self = this;
      option = jQuery.extend({
        setting      : null,
        previousLink : null,
        nextLink     : null,
        allow_manage   : false,
        allow_comment  : false
      }, option);
      this._setting = option.setting;
      this._target  = jQuery(target);

      this._allow_manage  = option.allow_manage;
      this._allow_comment = option.allow_comment;

      // register click event handler for paging links
      if( option.previousLink ){
        this._previousLink = jQuery(option.previousLink);
        this._previousLink.bind("click", function(){ self.loadPrevious(); });
      }
      if( option.nextLink  ){
        this._nextLink     = jQuery(option.nextLink);
        this._nextLink.bind("click",     function(){ self.loadNext(); });
      }
    },

    loadPublicEntries  : function(){
      var dom = this._target;
      var url = Page.getAbsoluteUrl("/components/blog/public/recent_entries.json");
      dom.wjNowLoading();
      jQuery.getJSON(url, function(entries){
        var jt = jQuery.createTemplateURL(Page.getAbsoluteUrl("/components/blog/javascripts/public_blog_entries.template.html"),
          null,
          {filter_data: false, filter_params : false});
        jt.setParam("Page", Page);
        dom.setTemplate(jt);
        dom.processTemplate(entries);
        dom.find("div.doc").corner("dog tr");
      });
    },

    loadEntries : function(direction) {
      var self = this;
      var dom = this._target;
      var url = Page.getAbsoluteUrl("/components/blog/settings/" + this._setting.id + "/entries.json?include_content=true");
      //  url direction handler
      url = this._resolvePageUrl(url, direction);
      if( url === null ){
        return;
      }
      dom.wjNowLoading();
      jQuery.getJSON(url, function(entries){
        // loadNext and loadPrevious
        self._entriesCache = entries;
        self.loadNext     = function(){ self.loadEntries("next");     };
        self.loadPrevious = function(){ self.loadEntries("previous"); };
        self._updatePageNavigationLink();

        var jt = jQuery.createTemplateURL(Page.getAbsoluteUrl("/components/blog/javascripts/blog_entries_view.template.html"),
          null,
          {filter_data: false, filter_params : false});
        jt.setParam("Page", Page);
        jt.setParam("Setting", self._setting);
        jt.setParam("AllowComment", self._allow_comment);
        jt.setParam("AllowManage",  self._allow_manage);

        dom.setTemplate(jt);
        dom.processTemplate(entries);
        dom.find("div.doc").corner("dog tr");
      });
    },

    _resolvePageUrl : function(baseUrl, direction){
      switch(direction){
      case "previous":
        if( this._entriesCache.previous.expected_offset < 0 ){
          return null;
        }else{
          return baseUrl + "&" + jQuery.wjParam(this._entriesCache.previous);
        }
      case "next":
        if( this._entriesCache.next.expected_offset < 0 ){
          return null;
        }else{
          return baseUrl + "&" + jQuery.wjParam(this._entriesCache.next);
        }
      default:
        return baseUrl;
      }
    },

    _updatePageNavigationLink : function(){
      var self = this;
      if( self._hasLink(self._entriesCache.next)) {
        self._nextLink.removeClass("disabled");
      }else{
        self._nextLink.addClass("disabled");
      }
      if( self._hasLink(self._entriesCache.previous)) {
        self._previousLink.removeClass("disabled");
      }else{
        self._previousLink.addClass("disabled");
      }
    },

    _hasLink : function(linkObj){
      if( linkObj === null ||
          linkObj.expected_offset < 0 ){
          return false;
      }
      else{
        return true;
      }
    }
  };
} // !Blog.EntryLoader
