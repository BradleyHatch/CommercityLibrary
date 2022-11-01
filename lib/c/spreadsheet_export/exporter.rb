# frozen_string_literal: true

# Exporter takes a series of rows and, on request, returns an XLSX workbook.
module C
  module SpreadsheetExport
    class Exporter
      DATE_FORMAT = 'yyyy/mm/dd'
      MONEY_FORMAT = '£0.00'

      def initialize(filename, rows, properties={})
        @filename = filename
        @rows = rows
        @properties = {
          title: 'Commercity Export',
          author: C.store_name,
          comments: "Created in Commercity #{Gem.loaded_specs['c'].version}"
        }.merge(properties)
      end

      # Creates a memoized format object containing our date format.
      def date_format
        @date_format ||= workbook.add_format(num_format: DATE_FORMAT)
      end

      # Creates a memoized format object containing our money format.
      def money_format
        @money_format ||= workbook.add_format(num_format: MONEY_FORMAT)
      end

      # Creates and memoizes the workbook object using the filename given in
      # the initializer.
      def workbook
        @workbook ||= WriteXLSX.new(@filename)
      end

      # Decides the best format for the value and then writes it to the sheet
      def write_cell(sheet, row_index, column_index, value)
        if value.is_a?(Money)
          sheet.write(row_index, column_index, value.to_f, money_format)
        elsif value.acts_like?(:time)
          sheet.write_date_time(row_index, column_index, value.iso8601,
                                date_format)
        else
          sheet.write(row_index, column_index, value.to_s)
        end
      end

      # Fill given sheet with the values in rows
      def populate_sheet(sheet)
        @rows.each_with_index do |columns, row_count|
          columns.each_with_index do |column, column_count|
            write_cell(sheet, row_count, column_count, column)
          end
        end
      end

      def export
        sheet = workbook.add_worksheet
        populate_sheet(sheet)
        workbook.set_properties(@properties)
        workbook.close
        workbook
      end
    end
  end
end
