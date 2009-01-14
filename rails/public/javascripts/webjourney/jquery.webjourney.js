(function() {
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
    var target = this;
    target.html("<div class='now_loading' />");
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

  jQuery.fn.wjDisplayErrors = function(name, errors, option){
    option = jQuery.extend({}, option);
    var message_list = "";
    for(var i=0; i<errors.length; i++){
      var err = errors[i];
      if( err.attr ){
        this.find("input[name='"    + name + "[" + err.attr + "]']").addClass("with_error");
        this.find("textarea[name='" + name + "[" + err.attr + "]']").addClass("with_error");
        this.find("select[name='"   + name + "[" + err.attr + "]']").addClass("with_error");
      }
      if( err.message ){
        message_list += "<li class='error'>" + err.message + "</li>";
      }
    }
    if( option.message ){
      var dom = jQuery(option.message);
      dom.css("display", "block");
      dom.html("<ul class='errors'>" + message_list + "</ul>");
    }
  };

  jQuery.fn.wjClearErrors = function(name, option){
    option = jQuery.extend({}, option);
    this.find("input.with_error").removeClass("with_error");
    this.find("textarea.with_error").removeClass("with_error");
    this.find("select.with_error").removeClass("with_error");
    if( jQuery(option.message) ){
      var dom = jQuery(option.message);
      dom.css("display", "none");
      dom.html("");
    }
  };

})(jQuery);
