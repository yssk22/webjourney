var INITIAL_CONTENT = "No content";
var CONVERTER = new Showdown.converter();
function format(content){
  return CONVERTER.makeHtml(content);
}

function registerEvents(){
  jQuery("#edit_content_button").bind("click",
                                      function(){
                                        jQuery("#show_content").hide();
                                        jQuery("#edit_content").show();
                                        gadgets.window.adjustHeight();
                                      });
  jQuery("#save_content_button").bind("click",
                                      function(){
                                        saveContent(
                                          function(){
                                            jQuery("#show_content").show();
                                            jQuery("#edit_content").hide();
                                            gadgets.window.adjustHeight();
                                          }
                                        );
                                      });
  jQuery("#cancel_content_button").bind("click",
                                        function(){
                                          jQuery("#show_content").show();
                                          jQuery("#edit_content").hide();
                                          gadgets.window.adjustHeight();
                                        });
}

function loadContent(callback){
  var reqkey = "load_content";
  var params = {
    userId: "@owner",
    groupId: "@self",
    keys: ["content"]
  };

  osapi.appdata.get(params).execute(
    function(data){
      var content = data["content"] || INITIAL_CONTENT;
      jQuery("#show_content .content").html(format(content));
      jQuery("#edit_content .content").text(content);
      callback && callback(content);
    });
}

function saveContent(callback){
  var content = jQuery("#edit_content textarea.content").val();
  var params = {
    userId: "@owner",
    groupId: "@self",
    data: {
      content: content
    }
  };
  osapi.appdata.update(params).execute(
    function(data){
      jQuery("#show_content .content").html(format(content));
      callback && callback(content);
    });
}

gadgets.util.registerOnLoadHandler(
  function(){
    registerEvents();
    loadContent(function(){
                  gadgets.window.adjustHeight();
                });
  });
