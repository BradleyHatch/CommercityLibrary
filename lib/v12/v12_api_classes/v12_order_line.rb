# frozen_string_literal: true

class V12OrderLine < V12Object
  attr_reader :order

  attr_reader :quantity
  attr_accessor :sku
  attr_accessor :item
  attr_reader :price # SINGLE UNIT price, NOT price*quantity! Can be negative for discounts

  def initialize(quantity, sku, item, price, parent)
    @quantity = quantity
    @sku = sku
    @item = item.delete("'").delete('"')
    @price = price
    @order = parent
  end

  def quantity=(value)
    @quantity = value
    @order.update_price
  end

  def price=(value)
    @price = value
    @order.update_price
  end

  def to_hash
    {
      'Qty': @quantity,
      'SKU': @sku,
      'Item': @item,
      'Price': @price
    }
  end
end
