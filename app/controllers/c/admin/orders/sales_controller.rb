# frozen_string_literal: true

require_dependency 'c/application_controller'
require 'xero/invoice'
require 'c/spreadsheet_export/orders'

module C
  module Admin
    module Orders
      class SalesController < AdminController
        include C::XeroSessionsHelper

        SAGE_ACTIONS = %i[sage_orders sage_results]

        load_and_authorize_resource instance_name: :order, class: C::Order::Sale, except: SAGE_ACTIONS
        skip_authorization_check only: SAGE_ACTIONS
        skip_before_action :authenticate_user!, only: SAGE_ACTIONS
        skip_before_action :verify_authenticity_token, only: SAGE_ACTIONS
        before_action :authenticate_sage_user, only: SAGE_ACTIONS
        before_action :set_paper_trail_whodunnit, except: SAGE_ACTIONS
        layout false, only: :print

        def new
          @order = C::Order::Sale.manual.pending.create!
          redirect_to @order
        end

        def index
          @q = if params[:q]
                 @orders.ordered.ransack(params[:q])
               else
                 @orders.ordered.awaiting_dispatch.ransack(params[:q])
               end
          @archive = C.allow_archive_all_orders
          @orders = C::Order::Sale.where(id: @q.result.pluck(:id).uniq).ordered.paginate(page: params[:page], per_page: C.sales_index_per_page)
        end

        def show
          @order = C::Order::Sale.find(params[:id])
          @notes = @order.notes
          @new_note = @order.notes.new
          @delivery = @order.delivery || @order.build_delivery
          @payment = @order.payment || @order.build_manual_payment
          @customer = @order.customer || @order.build_customer
        end

        def update
          @order.update(order_params)
          respond_to do |format|
            format.html do
              if params[:commit] == 'Insert Card Details and Print'
                redirect_to print_order_sales_path(
                  ids: @order,
                  cc: true,
                  cc_number_encrypt: params[:cc_number_encrypt],
                  cvv_encrypt: params[:cvv_encrypt],
                  expiry_encrypt: params[:expiry_encrypt]
                )
              else
                redirect_to @order
              end
            end
            format.js { render nothing: true }
          end
        end

        def print
          @orders = C::Order::Sale.where(id: params[:ids])
          @orders.each do |order|
            order.printed!
            # Ensure that delivery exists
            order.delivery.present? || order.build_delivery
          end
        end

        def mass_print
          orders = C::Order::Sale.where(status: :awaiting_dispatch, printed: false)
          redirect_to print_order_sales_path(ids: orders.pluck(:id))
        end

        # Capture all order statuses pages
        %i[awaiting_payment
           awaiting_dispatch
           dispatched
           cancelled
           archived
           all
           pending
           flagged
           carts].each do |method_name|
          define_method method_name do
            @f = C::Order::Sale.send(method_name)
            @f = @f.where.not(status: 'archived') if action_name == 'all'
            @q = @f.ordered.ransack(params[:q])
            @archive = method_name == :pending || 
                      method_name == :awaiting_payment || 
                      method_name == :awaiting_dispatch || 
                      method_name == :carts || 
                      method_name == :cancelled ||
                      method_name == :flagged ||
                      (C.allow_archive_all_orders && (
                        method_name == :dispatched ||
                        method_name == :all
                      ))
            @orders = @q.result.paginate(page: params[:page], per_page: C.sales_index_per_page)
            render :index
          end
        end

        def google_review_prompt
          ids = params[:ids]
          @sales = C::Order::Sale.where(id: ids)
        end

        def send_google_review_prompt
          ids = params[:ids].split(' ').map(&:to_i)
          @sales = C::Order::Sale.where(id: ids)

          @sales.each do |sale|
            next if sale.email&.blank?
            C::Enquiry.create(email: sale.email, name: sale.name ? sale.name : "n/a", google_prompt: true)
            C::OrderMailer.send_google_review_prompt(sale).deliver_now
          end
          
          flash[:success] = 'Google Review prompt emails will be sent out shortly'
          redirect_to order_sales_path
        end

        def bulk_actions
          case params[:bulk_actions]
          when 'dispatched'
            params[:sale].each { |o_id| C::Order::Sale.find(o_id).dispatched! }
          when 'print'
            redirect_to(print_order_sales_path(ids: params[:sale])) && return
          when 'xero'
            bulk_xero_export
            return
          when 'spreadsheet_item_list'
            spreadsheet_item_list_export
            return
          when 'archive_all'
            archive_all
            return
          when 'send_google_review_prompt'
            redirect_to(google_review_prompt_order_sales_path(ids: params[:sale]))
            return
          when 'download_as_csv'
            csv_headers = %w[number date status recipient address product_sku product_name quantity unit_price item_total sub_total delivery_service delivery_price vat total]

            order_ids = params[:sale]

            orders = C::Order::Sale.where(id: order_ids)

            rows = []

            orders.each do |order|
              row = [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
              row[0] = order.order_number
              row[1] = order.recieved_at
              row[2] = order.status
              row[3] = order.customer.present? ? "#{order.customer.name} #{order.customer.email}" : ""
              row[4] = order.shipping_address.present? ? "#{order.shipping_address.full_address_array.join(", ")}" : ""

              items = order.items.to_a
              item = items.shift
              
              if item.present?
                row[5] = item.sku
                row[6] = item.name
                row[7] = item.quantity
                row[8] = item.price.to_d
                row[9] = item.total_price.to_d
              end

              row[10] = order.total_price

              row[11] = order.delivery.present? ? "#{order.delivery.name}" : ""
              row[12] = order.delivery.present? ? order.delivery.price.to_d : nil
              row[13] = (order.total_tax + (order.delivery&.tax || 0)).to_d 
              row[14] = order.total_price_with_tax_and_delivery_pennies.to_d 

              rows.push(row)

              if items.any?
                items.each do |item|
                  item_row = [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
                  item_row[5] = item.sku
                  item_row[6] = item.name
                  item_row[7] = item.quantity
                  item_row[8] = item.price.to_d
                  item_row[9] = item.total_price.to_d
                  rows.push(item_row)
                end
              end

              # separator between the orders
              rows.push([nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil])
            end

            csv = CSV.generate do |csv|
              csv << csv_headers
              rows.each { |row| csv << row }
            end

            send_data csv,
                      type: 'text/csv; charset=iso-8859-1; header=present',
                      disposition: 'attachment; filename="orders_csv.csv"'
            return
          else
            flash[:notice] = 'Nothing to update'
          end
          redirect_back(fallback_location: order_sales_path)
        end

        def toggle_flag
          @order.toggle_flag("#{params[:state]}!")
          redirect_to @order
        end

        def new_dispatch_order
          @delivery = @order.delivery || @order.build_delivery
          respond_to do |format|
            format.js
            format.html
          end
        end

        def update_dispatch_order
          if @order.update(order_params)
            @order.send_dispatch_notification if (@order.web? || @order.manual?) && C.send_dispatch_notification
            @order.dispatch!
            redirect_to order_sales_path
          else
            render :new_dispatch_order
          end
        end

        def new_pro_forma_paid_order
          respond_to do |format|
            format.js
            format.html
          end
        end

        def update_pro_forma_paid_order
          if @order&.payment&.payable&.update(paid_at: Time.now)
            flash[:success] = 'Pro forma marked as paid'
            redirect_to order_sales_path
        else
            render :new_pro_forma_paid_order
          end
        end

        def stats; end

        def sage_orders
          orders = C::Order::Sale.exportable
          C::Order::Item.where(order_id: orders.pluck(:id)).where(product: nil).each do |order_item|
            order_item.update(product: C::Product::Variant.find_by(sku: order_item.sku.strip))
          end
          render json: orders.to_json(
            only: %i[id updated_at name email phone channel],
            include: {
              shipping_address: {
                only: %i[name first_name last_name address_one address_two address_three city region postcode],
                include: {
                  country: {
                    only: %i[iso2 name]
                  }
                }
              },
              billing_address: {
                only: %i[name first_name last_name address_one address_two address_three city region postcode],
                include: {
                  country: {
                    only: %i[iso2 name]
                  }
                }
              },
              customer: {
                only: %i[id name email phone sage_id]
              },
              items: {
                only: %i[sku name price_pennies price_currency quantity tax_rate],
                include: {
                  product: {
                    only: %i[bundle info],
                    include: {
                      bundle_items: {
                        only: %i[web_price_currency ebay_price_currency amazon_price_currency quantity],
                        include: {
                          bundled_variant: {
                            only: %i[sku name info]
                          }
                        },
                        methods: %i[web_price_ratio ebay_price_ratio amazon_price_ratio]
                      }
                    }
                  }
                },
                methods: %i[price_pennies_without_tax]
              },
              delivery: {
                only: :price_pennies
              },
              amazon_order: {
                only: %i[amazon_id buyer_email]
              },
              ebay_order: {
                only: %i[sales_record_id buyer_username]
              }
            }
          )
        end

        def sage_results
          JSON.parse(params[:results].gsub('\"', '"')).each do |order_result|
            order = C::Order::Sale.find(order_result['order_id'])
            if order_result['result']
              order.update(export_status: :succeeded)
            else
              order.update(export_status: :failed)
            end
            if order_result['error'].present?
              order.update(export_error_log: URI.unescape(order_result['error']))
            end
          end
        end

        def xero_export
          @order = C::Order::Sale.find(params[:id])
          begin
            C::Xero::Invoice.export!(xero_client, @order)
            flash[:success] = 'Invoice exported to Xero'
            redirect_to action: :show
          rescue Xeroizer::OAuth::TokenInvalid, Xeroizer::OAuth::TokenExpired
            redirect_to new_xero_session_path(type: 'order', target_id: @order.id)
          rescue C::Xero::InvoiceNotSavedError
            flash.now[:error] = 'Could not export invoice'
            show
            render :show
          end
        end

        def bulk_xero_export
          orders = C::Order::Sale.where(id: params[:sale])
          begin
            if C::Xero::Invoice.sync_invoices(xero_client, orders)
              flash[:success] = 'Orders exported to Xero'
              redirect_to order_sales_path
            else
              flash.now[:error] = 'There were errors in one of the selected orders'
              render :index
            end
          rescue Xeroizer::OAuth::TokenInvalid, Xeroizer::OAuth::TokenExpired
            redirect_to new_xero_session_path(type: 'bulk_order', target_id: params[:sale])
          end
        end

        def spreadsheet_item_list_export
          if params['order_months'].present?
            orders = C::Order::Sale.orders_from_month(params['order_months'])
          else
            orders = C::Order::Sale.where(id: params[:sale])
          end

          filename = "#{Time.zone.now.strftime('%Y%m%d%H%M%S')}_export.xlsx"
          tempfile = Tempfile.new(filename)
          C::SpreadsheetExport::Orders.to_item_list(
            orders,
            C::SpreadsheetExport::Orders::DEFAULT_ITEM_CONFIG,
            tempfile.to_path
          )
          send_file(
            tempfile.to_path,
            filename: filename,
            type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          )
        end

        def archive
          @order.archived!
          redirect_to C::Order::Sale
        end

        def archive_all
          C::Order::Sale.where(id: params[:sale]).find_each { |order| order.archived! }
          flash[:success] = 'Orders have been archived'
          redirect_to C::Order::Sale
        end

        private

        def order_params
          params.require(:order_sale).permit(
            :customer_id, :shipping_address_id, :billing_address_id,
            :name, :email, :phone, :mobile, :status, :export_status,
            info: C.order_info_fields.keys,
            notes_attributes: %i[note id _destroy],
            payment_attributes: [
              :id, :amount_paid,
              payable_attributes: %i[id body]
            ],
            customer_attributes: %i[id name email phone mobile],
            delivery_attributes: [:id,
                                  :courier_id,
                                  :courier_id,
                                  :provider,
                                  :price,
                                  :processing_at,
                                  :tax_rate,
                                  :shipped_at,
                                  trackings_attributes: %i[id
                                                           number
                                                           provider
                                                           _destroy]]
          )
        end

        def authenticate_sage_user
          unless C::User.find_by(email: params[:email])&.valid_password?(params[:password])
            render json: '[]', status: :unauthorized
          end
        end
      end
    end
  end
end
