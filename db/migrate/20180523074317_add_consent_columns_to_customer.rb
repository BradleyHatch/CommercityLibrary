class AddConsentColumnsToCustomer < ActiveRecord::Migration[5.0]
  def change
    add_column :c_customers, :consent_order, :boolean, default: false
    add_column :c_customers, :consent_promotion, :boolean, default: false
    add_column :c_customers, :consent_products, :boolean, default: false
    add_column :c_customers, :consent_contact_post, :boolean, default: false
    add_column :c_customers, :consent_contact_phone, :boolean, default: false
    add_column :c_customers, :consent_contact_email, :boolean, default: false
  end
end
