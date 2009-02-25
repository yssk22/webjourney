// this file register global functions
function h(str){
  return str.toString().replace(/\"/g,"&quot;")
  .replace(/</g,"&lt;")
  .replace(/>/g,"&gt;")
  .replace(/&/g,"&amp;");
}

function simple_format(str, html_options){
  var start_tag = tag("p", html_options, true);
  var text = str.toString().replace(/\r\n?/, "\n")
  .replace(/\n\n+/, "</p>\n\n" + start_tag)
  .replace(/([^\n]\n)(?=[^\n])/, '$1<br />');
  return start_tag + text + "</p>";
}

function tag(name, options, open){
  var dom = jQuery("<" + name + "/>");
  if( options ){ dom.attr(options); }
  var html = jQuery("<div/>").append(dom).html();
  if( open ){
    // remove close tag.
    return html.replace("</" + name + ">", "");
  }else{
    return html;
  }
}

// Extension for Date to support parsing ISO8601 format as followings:
// - yyyy-mm-ddThh:mm:ssZ      (UTC)
// - yyyy-mm-ddThh:mm:ss+dd:dd (Other)
Date.prototype.setISO8601 = function(str){
  if( str.match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\+|\-)(\d{2}):(\d{2})$/) ){
    // timezone specified.
    var _tmp = Date.UTC(
      RegExp.$1,
      RegExp.$2 - 1,
      RegExp.$3,
      RegExp.$4,
      RegExp.$5,
      RegExp.$6
    );
    var diff = (RegExp.$8 * 60 * 60 + RegExp.$9 * 60) * 1000;
    if( RegExp.$7 == "-" ){
      this.setTime(_tmp + diff);
    }else{
      this.setTime(_tmp - diff);
    }
  }
  else if( str.match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z$/) ){
    // timezone is utc.
    this.setTime(Date.UTC(
      RegExp.$1,
      RegExp.$2 - 1,
      RegExp.$3,
      RegExp.$4,
      RegExp.$5,
      RegExp.$6
    ));
  }
  else{
    throw("Invalid Date : " + str);
  }
  return this;
};

Date.prototype.strftime = function(format){
  return jQuery.strftime(format, this);
};