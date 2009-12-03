ACCOUNT_RULES = {
   username: {
      valid_username: true
   },
   password: {
      required: true,
      minlength: 4
   },
   password_confirm: {
      required: true,
      equalTo: "div#signup form input[name='password']"
   }
};

jQuery(function(){
   jQuery("#tabs").tabs();
   jQuery("div#login form").submit(function(e){
      e.preventDefault();
      login(jQuery(this));
      return false;
   });
   jQuery("div#signup form").submit(function(e){
      e.preventDefault();
      signUp(jQuery(this));
      return false;
   });

   jQuery.validator.addMethod("valid_username", function(val){
      return /^[a-zA-Z0-9_]{3,}$/.test(val);
   }, "Invalid user name format.");
   jQuery("div#signup form").validate({rules: ACCOUNT_RULES});
});

function login(form){
   jQuery("div#login").nowLoading({message: "Process authentication ..."});
   var user = jQuery("input[name='username']", form).val();
   var pass = jQuery("input[name='password']", form).val();
   var result = CouchDB.login(user, pass);
   if(result.ok){
      jQuery("div#login").nowLoading({message: "Now Loading your profile"});
      Site.go(Site.CouchApp.showPath("profile", Site.getUserId(user)));
   }else{
      jQuery("div#login").nowLoading("clear");
      alert(result.reason);
   }
}

function signUp(form){
   if(form.valid()){
      jQuery("div#signup").nowLoading({message: "Submitting ..."});
      var user = jQuery("input[name='username']", form).val();
      var pass = jQuery("input[name='password']", form).val();
      // TODO support email sign up
      var email = null;
      var result = CouchDB.createUser(user, pass, email);
      jQuery("div#signup").nowLoading("clear");
      if( result.ok ){
         alert("Signup successfully.");
         //Site.go(Site.CouchApp.showPath("login#login"));
      }else{
         alert(result.reason);
      }
   }
}