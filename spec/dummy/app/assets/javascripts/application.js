// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require jquery_ujs
//= require jquery.flexslider
//= require c/commercity.js
//= require_tree .

$(function () {

  $('.home-block--slider').each( function() {

    $(this).flexslider({
        animation: "slide",
        controlNav: false,
        directionNav: true,
        slideshow: true,
        slideshowSpeed: 2000,
        move: 1,
        prevText: '<i class="fa fa-chevron-left" aria-hidden="true"></i>',
        nextText: '<i class="fa fa-chevron-right" aria-hidden="true"></i>'
    });

  });

});
