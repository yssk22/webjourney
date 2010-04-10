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
      // special type : date_select
      form.find("select[type='date_select_year']").each(function(){
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
         if( elm.attr("type") ){ return; }
         var val = elm.val();
         if(!val){ return; }
         setDocVal(doc, elm.attr("name"), val);
      });
      return doc;
   },


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