(function() {
   var _get_default_dom = function(dom, selector, on){
     if(on){ return jQuery(on);}
     else  { return jQuery(selector, dom); }
   };

   jQuery.extend({
     // alternative for jQuery.param() to support Rails convention about Array
     // for example,
     // var a = { arr : [1,2,3] }
     // jQuery.param(a);   // => arr=1&arr=2&arr=3        // treated only first element as "arr" parameter on rails server
     // jQuery.wjParam(a); // => arr[]=1&arr[]=2&arr[]=3  // treated perfectly on rails server
     wjParam : function(a){
       if ( a.constructor == Array || a.jquery ){
         return jQuery.param(a);
       }else{ // key value pairs
         var s = [];
         for(var j in a){
           if ( a[j] && a[j].constructor == Array ){
             if ( a[j].length > 0 ){
               jQuery.each( a[j], function(){
                 s.push( encodeURIComponent(j) + "[]=" + encodeURIComponent( this ) );
               });
             }else{
               s.push( encodeURIComponent(j) + "[]=");
             }
           }else{
             s.push( encodeURIComponent(j) + "=" + encodeURIComponent( jQuery.isFunction(a[j]) ? a[j]() : a[j] ) );
           }
         }
         return s.join("&").replace(/%20/g, "+");
       }
     }
   });

   // wapper for jQuery#load method
   jQuery.fn.wjLoad = function(url, data, callback){
     var target = this;
     target.wjNowLoading();
     target.load(url, data, callback);
   };

   jQuery.fn.wjNowLoading = function(option){
     option = jQuery.extend({overlay: true}, option);
     var target = this;
     if(option.overlay){
       // append overlay div block
       var dom = jQuery(document.createElement("div"));
       dom.css("display", "none");
       dom.addClass("now_loading");
       dom.addClass("overlay");
       dom.width(this.outerWidth());
       dom.height(this.outerHeight());
       var offset = this.offset();
       dom.css("top",  offset.top);
       dom.css("left", offset.left);
       dom.css("display", "block");
       target.prepend(dom);
     }else{
       target.html("<div class='now_loading'></div>");
     }
   };

   jQuery.fn.wjClearOverlay = function(){
     jQuery("div.overlay", this).remove();
   };


   jQuery.fn.wjDisableSubmit = function(option){
     option = jQuery.extend({submitting: true}, option);
     var target = this;
     target.attr("disabled", "disabled");
     if( option.submitting ){
       target.attr("class", "submitting");
     }else{
       target.attr("class", "submit");
     }
   };

   jQuery.fn.wjEnableSubmit = function(option){
     var target = this;
     target.attr("disabled", null);
     target.attr("class", "submit");
   };

   /*
    * Handle Error resources and display it on the display block.
    */
   jQuery.fn.wjDisplayErrors = function(errors, option){
     option = jQuery.extend({}, option);
     var param_path2name = function(param_path){
       var name = param_path[0];
       for(var i=1; i<param_path.length; i++){
         name += "[" + param_path[i] + "]";
       }
       return name;
     };
     // get (param, message) pair list
     var pe_pairs = [];
     (function(obj, path){
        var fun = arguments.callee;
        jQuery.each(obj, function(name){
                      var param_path = jQuery.extend([], path);
                      param_path.push(name);
                      if( this.constructor == Array ){
                        pe_pairs.push({
                          param : param_path2name(param_path),
                          errors : this
                        });
                      }else if( this.constructor == String ){
                        pe_pairs.push({
                          param : param_path2name(param_path),
                          errors : [this]
                        });
                      }else{
                        fun(this, param_path); // recursive call
                      }
                    });
      })(errors);
     var message_list = "";
     for(var i=0; i<pe_pairs.length; i++){
       var param = pe_pairs[i].param;
       var messages = pe_pairs[i].errors;
       this.find("label[for='" + param + "']").addClass("error");
       this.find("input[name='" + param + "']").addClass("error");
       this.find("textarea[name='" + param + "']").addClass("error");
       this.find("select[name='" + param + "']").addClass("error");
       for(var j=0; j<messages.length; j++){
         message_list += "<li class='error'>" + messages[j] + "</li>";
       }
     }
     var dom = _get_default_dom(this, "div.error", option.on);
     dom.css("display", "block");
     dom.html("<ul class='errors'>" + message_list + "</ul>");
   };

   jQuery.fn.wjClearErrors = function(name, option){
     option = jQuery.extend({}, option);
     this.find("input.error").removeClass("error");
     this.find("textarea.error").removeClass("error");
     this.find("select.error").removeClass("error");
     var dom = _get_default_dom(this, "div.error", option.on);
     dom.css("display", "none");
     dom.html("");
   };

   jQuery.fn.wjDisplayInfo = function(option){
     option = jQuery.extend({}, option);
     var dom = _get_default_dom(this, "div.info", option.on);
     if( option.msg ){
       dom.html(option.msg);
     }
     dom.effect("bounce", { times: 3 }, 300);
     dom.css("display", "block");
   };

   jQuery.fn.wjClearInfo = function(option){
     option = jQuery.extend({}, option);
     var dom = _get_default_dom(this, "div.info", option.on);
     dom.css("display", "none");
   };
})(jQuery);
