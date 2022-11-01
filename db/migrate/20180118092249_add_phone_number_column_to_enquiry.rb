class AddPhoneNumberColumnToEnquiry < ActiveRecord::Migration[5.0]
  def up
    unless C::Enquiry.column_names.include?("phone_number")
      add_column :c_enquiries, :phone_number, :string
    end
  end

  def down
    if C::Enquiry.column_names.include?("phone_number")
      remove_column :c_enquiries, :phone_number, :string
    end
  end
end
