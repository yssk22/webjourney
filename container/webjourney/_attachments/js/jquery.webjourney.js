(function(){
   var msgDef = {
      "infoMsg" : {
         state: "ui-state-highlight",
         icon: "ui-icon-info"
      },
      "errorMsg" : {
         state: "ui-state-error",
         icon: "ui-icon-alert"
      }
   };

   function msg(obj, type, options){
      var def = msgDef[type];
      var opts;
      if( options == "clear" ){
         opts = "clear";
      }else{
         if(typeof(options) == 'object'){
            opts = jQuery.extend({
               message : "Message..."
            }, options);
         }else{
            opts = jQuery.extend({
               message : options
            });
         }
      }
      return obj.each(function(){
         var target = jQuery(this);
         if( opts == "clear" ){
            target.hide();
         }else{
            var html = '<div class="ui-corner-all ' + def.state + ' ' + type + '">';
            html += '<p><span class="ui-icon ' + def.icon + ' icon"></span>';
            html += opts.message + '</p></div>';
            target.html(html);
         }
      });
   }

   jQuery.fn.errorMsg = function(options){
      msg(this, "errorMsg", options);
   };
   jQuery.fn.infoMsg = function(options){
      msg(this, "infoMsg", options);
   };

   jQuery.fn.nowLoading = function(options){
      var opts;
      if( options == "clear" ){
         opts = "clear";
      }else{
         opts = jQuery.extend({
            message : "Now Loading ..."
         }, options);
      }
      return this.each(function(){
         var target = jQuery(this);
         var overlay = jQuery("div.now_loading", target);
         switch(opts){
         case "clear":
            if( overlay.length ){
               overlay.remove();
            }
            break;
         default:
            if( overlay.length == 0 ){
               overlay = jQuery(document.createElement("div"));
               overlay.css("display", "none");
               overlay.addClass("now_loading");
               overlay.width(target.outerWidth());
               overlay.height(target.outerHeight());
               var pos = target.position();
               overlay.css("top", pos.top);
               overlay.css("left", pos.left);
               overlay.css("display", "block");
               target.prepend(overlay);
            }
            // place the overlay
            overlay.html('<div>' +
                         '<span class="message">' + opts.message + '</span>' +
                         '</div>');
            // move to center
            var block = jQuery("div", overlay);
            block.css("margin-top", (overlay.outerHeight() - block.outerHeight())/ 2);
            break;
         }
      });
   };
})(jQuery);