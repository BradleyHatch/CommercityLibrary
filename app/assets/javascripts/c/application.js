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
//= require jquery
//= require jquery-ui
//= require jquery_ujs

//= require cable

//= require dropzone
//= require ./draggable_tree
//= require select2
//= require nested_form_fields

//= require ./ebay_cats
//= require ./unloadevent
//= require ./split_selector
//= require ./shipping_service_nested_fields

//=require ./dropzone_init
//= require ./amazon_cats_and_attributes
//= require ./property_values
//= require ./things_to_be_done
//= require cd2_tabs_cookies
//= require ./components/components
//= require 'tinymce-jquery'

//= require chartkick
//= require Chart.bundle

function readyFunctions() {
  $(".select2").select2()
  orderItemCustomerPicker()
  productReadyFunctions()
  defaultDropzone()
}

function productReadyFunctions() {
  amazonCategoriesAttributes()
  ebayCategories()
  searchableSelectFields()
  splitSelector()
  reorderableElements()
  productDropzone()
  sortThisOut()
  propertyValues()
}

$(function () {
  $(".index_key--toggle").on("click", function () {
    $(".index_key").toggleClass("index_key--show")
  })

  readyFunctions()

  $("[data-enc]").on("change", function (e) {
    console.log(e.target.value)
    var encced = CryptoJS.AES.encrypt(e.target.value, "Secret Passphrase")
    $("#" + $(this).data("enc")).val(encced)
  })

  $("[data-dec]").each(function (e) {
    var decced = CryptoJS.AES.decrypt(
      $(this).data("dec"),
      "Secret Passphrase"
    ).toString(CryptoJS.enc.Utf8)
    $(this).text(decced)
  })

  $(".field--float-label input").on("input", function () {
    var $field = $(this).closest(".field--float-label")
    if (this.value) {
      $field.addClass("field--not-empty")
    } else {
      $field.removeClass("field--not-empty")
    }
  })

  $(".collapsing-form-panel__toggle").on("click", function () {
    $(".collapsing-form-panel").toggleClass("collapsing-form-panel--collapsed")
  })

  $("body").on("click", "[data-toggle-post]", function () {
    var master = $(this).data("master-id")
    $.post(
      "/admin/products/" +
        master +
        "/toggle_" +
        $(this).data("path") +
        "?obj_id=" +
        $(this).attr("value")
    )
  })

  $("body").on("click", "[data-toggle-table] [data-toggle-post]", function () {
    var $this = $(this).closest("tbody")
    $this.find(".sort_handle").removeClass("sort_handle")
    $this.find("i").remove()
  })
})
