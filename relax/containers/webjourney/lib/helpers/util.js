function html_escape(s){
  return s.toString().replace(/&/g, "&amp;").
    replace(/\"/g, "&quot;").
    replace(/\'/g, "&#039;").
    replace(/</g, "&lt;").
    replace(/>/g, "&gt;");
}

function h(s){
  return html_escape(s);
}

function json_escape(s){
  return s.toString().relace(/&/g, "\\u0026").
    replace(/</g, "\\u003c").
    replace(/>/g, "\\u003e");
}

function j(s){
  return json_escape(s);
}