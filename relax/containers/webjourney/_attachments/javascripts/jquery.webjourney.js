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

   jQuery.fn.clear = function(){
      this.each(function(){
         var dom = this;
         var tag = dom.tagName.toLowerCase();
         var type = dom.type;
         if( type == "text" || type == "password" || tag == "textarea"){
            jQuery(dom).val("");
         }else if( type == "checkbox" || type == "radio" ){
            jQuery(dom).attr("checked", "");
         }else{
            dom.selectedIndex = -1;
         }
      });
   },

   jQuery.fn.serializeJson = function(options){
      var opts = jQuery.extend({fields: []}, options);
      var form = this;
      var doc = {};

      function setDocVal(to, path_name, value){
         var paths = path_name.split("-");
         var field = to, member = paths.shift();
         while (paths.length > 0) {
            field[member] = field[member] || {};
            field = field[member];
            member = paths.shift();
         }
         field[member] = value;
      }

      // for input field
      form.find("input").each(function(){
         var elm = jQuery(this);
         var val;
         switch(elm.attr("type")){
         case "radio":
         case "checkbox":
            if( elm.attr("checked") ){
               val = JSON.parse(elm.val());
            }
            break;
         default: // hidden or text
            val = elm.val();
            break;
         }
         if(!val){ return; }
         setDocVal(doc, elm.attr("name"), val);
      });

      // for textarea
      form.find("textarea").each(function(){
         var elm = jQuery(this);
         var val = elm.val();
         if(!val){ return; }
         setDocVal(doc, elm.attr("name"), val);
      });
      // for selection
      // special crayon_type : date_select
      form.find("select[crayon_type='date_select_year']").each(function(){
         var elm = jQuery(this);
         var y, m, d;
         y = elm.val();
         var date_name = elm.attr("name").split("-");
         date_name[date_name.length-1] = "month";
         m = form.find("select[name='" + date_name.join("-") + "']").val();
         date_name[date_name.length-1] = "day";
         d = form.find("select[name='" + date_name.join("-") + "']").val();
         if(!y){ return; }
         if(!m){ return; }
         if(!d){ return; }
         date_name.splice(date_name.length - 1);
         setDocVal(doc, date_name.join("-"), new Date(y + "/" + m + "/" + d));
      });
      // normal select
      form.find("select").each(function(){
         var elm = jQuery(this);
         // skip crayon type
         if( elm.attr("crayon_type") ){ return; }

         var val = elm.val();
         if(!val){ return; }
         setDocVal(doc, elm.attr("name"), val);
      });
      return doc;
   },

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