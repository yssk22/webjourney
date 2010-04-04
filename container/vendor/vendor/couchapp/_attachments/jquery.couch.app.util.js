$.log = function() {
  if (window && window.console && window.console.log) {
    window.console.log(arguments);
  }
};

// todo remove this crap
function escapeHTML(st) {                                       
  return(                                                                 
    st && st.replace(/&/g,'&amp;').                                         
      replace(/>/g,'&gt;').                                           
      replace(/</g,'&lt;').                                           
      replace(/"/g,'&quot;')                                         
  );                                                                     
};

function safeHTML(st, len) {
  return st ? escapeHTML(st.substring(0,len)) : '';
}

// todo this should take a replacement template
$.linkify = function(body) {
  return body.replace(/((ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?)/gi,function(a) {
    return '<a target="_blank" href="'+a+'">'+a+'</a>';
  }).replace(/\@([\w\-]+)/g,function(user,name) {
    return '<a href="#/mentions/'+encodeURIComponent(name)+'">'+user+'</a>';
  }).replace(/\#([\w\-\.]+)/g,function(word,tag) {
    return '<a href="#/tags/'+encodeURIComponent(tag)+'">'+word+'</a>';
  });
};

$.prettyDate = function(time){
	var date = new Date(time),
		diff = (((new Date()).getTime() - date.getTime()) / 1000),
		day_diff = Math.floor(diff / 86400);

  if (isNaN(day_diff)) return time;

	return day_diff < 1 && (
			diff < 60 && "just now" ||
			diff < 120 && "1 minute ago" ||
			diff < 3600 && Math.floor( diff / 60 ) + " minutes ago" ||
			diff < 7200 && "1 hour ago" ||
			diff < 86400 && Math.floor( diff / 3600 ) + " hours ago") ||
		day_diff == 1 && "yesterday" ||
		day_diff < 21 && day_diff + " days ago" ||
		day_diff < 45 && Math.ceil( day_diff / 7 ) + " weeks ago" ||
		day_diff < 730 && Math.ceil( day_diff / 31 ) + " months ago" ||
		Math.ceil( day_diff / 365 ) + " years ago";
};
