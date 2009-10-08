/**
 * jQuery Extention for WebJourney
 */
(function(){
   jQuery.extend(
     {
       /**
        * Finds the first element of an array which satisfy a filter function.
        */
       findFirst : function(a, callback, invert){
         return this.grep(a, callback, invert)[0];
       }
     }
   );
 })(jQuery);