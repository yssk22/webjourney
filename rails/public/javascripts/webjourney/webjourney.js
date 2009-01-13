var WebJourney = {};


// put authtoken into global ajax hanlder

jQuery(document).ajaxSend(function(event, request, settings) {
  if (typeof(AUTH_TOKEN) == "undefined") return;
  if( (settings.type.toLowerCase() == "post" || settings.type.toLowerCase() == "put") &&
       settings.contentType == "application/x-www-form-urlencoded"){
    settings.data = settings.data || "";
    settings.data += (settings.data ? "&" : "") + "authenticity_token=" + encodeURIComponent(AUTH_TOKEN);
    request.setRequestHeader("Content-Type", settings.contentType);
  }
});
