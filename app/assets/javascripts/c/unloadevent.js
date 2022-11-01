(function($, window){

  $(window).on('load', function(){

    var unsaved_changes = false;

    $(":input").change(function(){
      $form = $(this).closest('form');
      if (!$form.data('skip-alert')) {
        unsaved_changes = true;
        $form.on('submit', function(){
          unsaved_changes = false;
        });
      }
    });

    function unloadPage(e){
      if(unsaved_changes){
        return true;
      }
    }

    window.onbeforeunload = unloadPage;

    if ($('.error').length > 0) {
      unsaved_changes = true;
    }

  });

}(jQuery, window));
