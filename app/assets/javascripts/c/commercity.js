$(window).on("load page:load turbolinks:load", function(event) {
    $(".submit_cart_button").on("click", function(event) {

        if ( $(this).data('bypass-cart') ) {
          var bypassParam = $("<input>").attr("type", "hidden").attr("name", "bypass_cart").val(true);
          $(this).closest("form").append($(bypassParam));
        }

        $(this).closest("form").submit();
    });

    var $main = $('.product-show__main_image > img');

    $('.product-show__thumbnail').on('click', function(){
        var url = $(this).attr('src').replace('thumbnail_', '');

        if ( $(this).data('content-thumbnail') ) {
          var preview_url = $(this).attr('src').replace('thumbnail_', 'large_');
        } else if ( $main.attr('src').indexOf('no_pad') >= 0 ) {
          var preview_url = $(this).attr('src').replace('thumbnail_', 'product_standard_no_pad_');
        } else {
          var preview_url = $(this).attr('src').replace('thumbnail_', 'product_standard_');
        }

        $main.attr('src', preview_url);
    });



});
