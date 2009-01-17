ViewEntry = {
  setSettingId : function(val){ this._setting_id = val; },
  setEntryId   : function(val){ this._entry_id = val; },

  loadComment : function(){
    var dom = Page.getDom('entry_permalink div.comment div.list');
    var url = Page.getAbsoluteUrl("/components/settings/" + this._setting_id +
                                  "/entries/" + this._entry_id +
                                  "/comments.json");
    dom.wjLoad(url, function(comments){
    });
  },

  onPostBlogCommentSuccess : function(request){
    var dom = Page.getDom('entry_permalink div.comment form:first');
    dom.wjClearErrors();
    dom.find("textarea").val("");
  },

  onPostBlogCommentFailure : function(request){
    if(request.status === 400){
      var json = jQuery.parseJSON(request.responseText);
      var dom = Page.getDom('entry_permalink div.comment form:first');
      dom.wjDisplayErrors('comment', json.errors);
    }
  }
};