WebJourney.ComponentPage = function(){
    this.initialize.apply(this, arguments);
};
WebJourney.ComponentPage.prototype = jQuery.extend(new WebJourney.PageBase,{
  initialize : function(){
    WebJourney.PageBase.prototype.initialize.apply(this);
  },

  getDomId : function(suffix){
    if(suffix){ return "cpm_body_" + suffix; }
    else      { return "cpm_body"; }
  },

  getDom : function(suffix){
    return $("#" + this.getDomId(suffix));
  },

  highlightCPN : function(){
    $("div#cpn div#cpn_body ul li a").each(
      function(index){
        if(this.href == window.location.href){
          $(this).addClass("current");
        }else{
          $(this).removeClass("current");
        }
      }
    );
  }
});