class AddCreatedByReferenceToCOrderNotes < ActiveRecord::Migration[5.0]
  def change
    add_reference :c_order_notes, :created_by
  end
end
