# frozen_string_literal: true
class MoveBarcodesIntoSeperateModel < ActiveRecord::Migration[5.0]
  def up
    query = C::Product::Variant
            .where.not(barcode_value: nil, barcode_type: nil)
    total = query.count
    padding = [Math.log10(total), 0].max.to_i + 1

    query.pluck(:id, :barcode_value, :barcode_type).each_with_index do |data, i|
      id, v, t = data

      # Status
      print (' ' * 30) + "\r"
      print " (#{(i + 1).to_s.rjust(padding)}/#{total}) #{id}...\r"
      $stdout.flush

      next if v.blank?

      C::Product::Barcode.create!(
        variant_id: id,
        value: v,
        symbology: t.blank? ? :EAN : t
      )
    end
  end

  def down
    query = C::Product::Variant.all
    total = query.count
    padding = [Math.log10(total), 0].max.to_i + 1

    C::Product::Variant.all.includes(:barcodes).each_with_index do |v, i|
      # Status
      name = v.name.present? ? v.name : 'Not named'
      print (' ' * 115) + "\r"
      print " (#{(i + 1).to_s.rjust(padding)}/#{total}) #{name[0..80]}...\r"
      $stdout.flush

      barcode = v.barcode
      if barcode
        v.update!(barcode_value: barcode.value,
                  barcode_type: barcode.symbology)
      end
    end
  end
end
