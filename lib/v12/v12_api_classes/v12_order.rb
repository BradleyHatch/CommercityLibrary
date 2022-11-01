# frozen_string_literal: true

class V12Order < V12Object
  attr_reader :lines

  attr_accessor :p_id
  attr_accessor :p_guid
  attr_accessor :sales_ref
  attr_reader :price # total of price*quantity for each line
  attr_accessor :deposit # is this setable?

  def initialize(p_id, p_guid, sales_ref, deposit)
    @p_id = p_id
    @p_guid = p_guid
    @sales_ref = sales_ref
    @deposit = deposit
    @price = 0
    @lines = {}
  end

  def add_line(quantity, sku, item, price)
    new_line = V12OrderLine.new(quantity, sku, item, price, self)
    add(new_line)
  end

  def add(line)
    @lines[@lines.length] = line
    @price += line.price * line.quantity
  end

  def update_price
    @price = 0
    @lines.each do |_, line|
      @price += line.price * line.quantity
    end
  end

  def to_hash
    result = { 'ProductId': @p_id,
               'ProductGuid': @p_guid,
               'SalesReference': @sales_ref,
               'CashPrice': @price,
               'Deposit': @deposit }
    if @lines
      lines_arr = []
      @lines.each { |_, line| lines_arr << line.to_hash }
      result['Lines'] = lines_arr
    end
    result
  end
end
