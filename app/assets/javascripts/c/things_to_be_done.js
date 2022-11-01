var orderItemCustomerPicker = function(){
    $('.order_item_picker select').on('change', function () {
        $.getJSON("/admin/variants/" + $('.order_item_picker select').val(),
            function(data){
                $('[name="order_item[name]"]').val(data.variant.name)
                $('[name="order_item[sku]"]').val(data.variant.sku)
                $('[name="order_item[tax_rate]"]').val(data.master.tax_rate)
                $('[name="order_item[price]"]').val(data.variant.retail_price_pennies / 100)
            });
    })

    $('.customer_picker select').on('change', function () {
        $.getJSON("/admin/customers/" + $('.customer_picker select').val() + '.json',
            function(data){
                $('[name="order_sale[name]"]').val(data.name)
                $('[name="order_sale[email]"]').val(data.email)
                $('[name="order_sale[phone]"]').val(data.phone)
                $('[name="order_sale[mobile]"]').val(data.mobile)
            });
    })
}

var reorderableElements = function(){
    $('.reorderable').sortable({
        axis:'y',
        handle: '.sort_handle',
        tolerance: 'pointer',
        containment: 'parent',
        revert: 50,
        update: function(){
          $('.order_field', this).each(function(i){
            $(this).val(i)
          })
        }
    });

    $('.sortable_table tbody').sortable({
        axis:'y',
        handle: '.sort_handle',
        tolerance: 'pointer',
        containment: 'parent',
        revert: 50,
        update: function(){
          $.ajax({
            url: $(this).attr('index_data-sort'),
            method: 'POST',
            dataType: 'script',
            data: $(this).sortable('serialize')});
        }
    });

}

var searchableSelectFields = function(){
  $('select[data-searchable-select]').select2();
  $('.select2').select2();
  $('select[multiple]').each(function (i, e) {
    $e = $(e);
      console.log($e.data('pagination'))
    if ($e.data('max-choices')) {
      $e.select2({
        maximumSelectionLength: $e.data('max-choices')
      });
    }
    else {
      $e.select2();
    }
  });
}

var sortThisOut = function(){
    $('[data-add-key]').on('click', function(e){
      e.preventDefault();

      $new = $(this).prev().clone()

      $new.find('.fields--stacked input:not(:first)').remove()
      $new.find('input').val('')
      $new.insertBefore($(this))
    })


    $('[data-add-value]').on('click', function(e){
      e.preventDefault();
      $new = $(this).prev().clone()

      $new.find('input').val('')
      $new.insertBefore($(this))
    })

    $('#select_all').change(function(){  //'select all' change
    var status = this.checked; // 'select all' checked status
      $('.check_box_column input').each(function(){ //iterate all listed checkbox items
          this.checked = status; //change '.checkbox' checked status
      });
    });

    $('.check_box_column input').change(function(){ //'.checkbox' change
      //uncheck 'select all', if one of the listed checkbox item is unchecked
      if(this.checked === false){ //if this item is unchecked
          $('#select_all')[0].checked = false; //change 'select all' checked status to false
      }

      //check 'select all' if all checkbox items are checked
      if ($('.check_box_column input:checked').length === $('.check_box_column input').length ){
          $('#select_all')[0].checked = true; //change 'select all' checked status to true
      }
    });

    $('input:checkbox').change(function(){
      if($('input:checkbox').is(':checked')) {
          $('html').addClass('bulk_actions_show');
      } else {
          $('html').removeClass('bulk_actions_show');
      }
    });

}
