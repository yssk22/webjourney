App = null;
$(function(){
   $("header#header nav a.logout").click(logout);
   $("button.ui-button").button();
});
$.couch.app(function(app){
   App = app;
});


function logout(){
   $.couch.logout({
      success: function(resp){
         window.location.href = App.showPath("top");
      }
   });
}

function log(msg){
   if(console != undefined && console.log != undefined ){
      console.log(msg);
   }
}
