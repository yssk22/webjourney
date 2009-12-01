/**
 * jQuery Extention for WebJourney
 */
(function(){
   jQuery.extend({
      /**
       * Finds the first element of an array which satisfy a filter function.
       */
      findFirst : function(a, callback, invert){
         return this.grep(a, callback, invert)[0];
      }
   });

   jQuery.fn.nowLoading = function(options){
      var opts;
      if( options == "clear" ){
         opts = "clear";
      }else{
         opts = jQuery.extend({
            message : "Now Loading ...",
            img     : Site.imagePath("now_loading.gif")
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
               var offset = target.offset();
               overlay.css("top", offset.top);
               overlay.css("left", offset.left);
               overlay.css("display", "block");
               target.prepend(overlay);
            }
            // place the overlay
            overlay.html('<div>' +
                     '<img src="' + opts.img +'" width="32" height="32" alt="' + opts.message + '" />' +
                     '<span>' + opts.message + '</span>' +
                     '</div>');
            // move to center
            var block = jQuery("div", overlay);
            block.css("margin-top", (overlay.outerHeight() - block.outerHeight())/ 2);
            break;
         }
      });
   };
})(jQuery);