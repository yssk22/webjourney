function clearButton(selector){
   return '<button type="button" onclick=\'jQuery(' + h(toJSON(selector)) + ').clear()\'>Clear</button>';
}