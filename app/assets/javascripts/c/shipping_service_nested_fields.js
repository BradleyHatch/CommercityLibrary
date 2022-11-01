// Sets event listener for adding nested fields for ebay shipping services
// that sneaks in a hidden field to set a boolean attribute to true

$(function () {

  if ( $('#ebay-international-services').length > 0 ) {

    $(document).on('fields_added.nested_form_fields', function(event, param) {

      var $index = param.added_index;
      var $data = $(event.currentTarget.activeElement).data('insert-into')

      if ( $data === 'ebay-international-services' ) {
        var input = "<input value='true' type='hidden' name='product_master[ebay_channel_attributes][shipping_services_attributes]["+$index+"][international]' id='product_master_ebay_channel_attributes_shipping_services_attributes_"+$index+"_international'>"
        $('#ebay-international-services .nested_fields').last().append(input);
      }

    });

  }

});
