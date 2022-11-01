function splitSelector() {

  if ( $('.split_selector').length > 0 ) {

    $('.split_selector a').on('click', function() {
      $('.quick_actions').toggleClass('hidden');
    })

  }

}
