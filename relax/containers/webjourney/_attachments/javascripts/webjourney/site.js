WebJourney.Site = WebJourney.Site || function(){
   this.initialize.apply(this, arguments);
};
WebJourney.Site.Foo = "bar";

WebJourney.Site.prototype = {
   initialize: function(app){
      var self = this;
      var path = window.location.pathname.split("/");
      this.CouchApp = app;
      this._root     = ["", path[1]].join("/");
      this._app_root = ["", path[1], "_design", path[3]].join("/");
      this._img_root = [this._app_root, "images"].join("/");
      this._js_root  = [this._app_root, "javascripts"].join("/");
      this._css_root = [this._app_root, "stylesheets"].join("/");
      this._domain   = window.location.host;
   },

   logout: function(){
      CouchDB.logout();
      this.go(this.CouchApp.showPath("page", "top"));
   },

   go: function(path){
      window.location.href = path;
   },

   goShow : function(show, docId, params){
      // TDB
   },

   goList : function(list, view, params){
      // TDB
   },

   imagePath : function(path){
      return [this._img_root, path].join("/");
   },

   getUserId : function(username){
      // domain prefiexed user id
      return this._domain + ":" + username;
   }
};

Site = null;
$.CouchApp(function(app){
   Site = new WebJourney.Site(app);
});
