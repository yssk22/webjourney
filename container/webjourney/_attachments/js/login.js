function onLoginSubmit(){
   var name = $("#login input[name='name']").val();
   var pass = $("#login input[name='password']").val();
   $("#login").nowLoading({message: "Connecting ..."});
   $.couch.login({
      name : name,
      password : pass,
      success : function() {
         var path = App.showPath("profile", "p:" + encodeURIComponent(name));
         log("Succ - " + path);
         $("#login p.msg").infoMsg("Now redirecting your page ...");
         window.location.href = path;
      },
      error : function(code, error, reason) {
         log("Error - " + reason);
         $("#login").nowLoading("clear");
         $("#login p.msg").errorMsg("Invalid name or password");
      }
   });
   return false;
}

$(function(app){
   $("#login").submit(onLoginSubmit);
});