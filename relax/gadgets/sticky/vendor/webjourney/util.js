// rendering template with binding
function render(template,bindings){
  bindings = bindings || {};
  bindings.couchapp = couchapp;
  var result = new EJS({text: template}).render(bindings);
  send(result);
  return result;
}