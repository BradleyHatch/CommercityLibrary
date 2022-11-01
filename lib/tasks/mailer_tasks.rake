# frozen_string_literal: true

namespace :c do
  namespace :mailer do
    task abandoned_cart: :environment do

      abandoned_cart_mailouts = -> (carts, days_count) do
        rich_body = <<-HTML
          <p>
            You haven't updated your cart for #{days_count} days. Click <a target='_blank' href='#{C.domain_name}/cart'>here</a> to view your cart and complete your checkout.
          </p>
        HTML
        text_body = "You haven't updated your cart for #{days_count} days. Visit #{C.domain_name}/cart to view your cart and complete your checkout."
        carts.each do |cart|
          next unless cart&.customer
          abandoned_attribute = "abandoned_mailout_#{days_count}_day"
          cart.update_columns(abandoned_attribute => true)
          voucher = days_count == :seven ? cart.generate_abandoned_voucher : nil
          C::OrderMailer.send_abandon_mailout(cart, rich_body, text_body, voucher).deliver_now
        end
      end

      three_day = C::Cart.not_completed_three_days.where.not(abandoned_mailout_three_day: true)
      five_day = C::Cart.not_completed_five_days.where.not(abandoned_mailout_five_day: true)
      seven_day = C::Cart.not_completed_seven_days.where.not(abandoned_mailout_seven_day: true)

      abandoned_cart_mailouts[three_day, :three]
      abandoned_cart_mailouts[five_day, :five]
      abandoned_cart_mailouts[seven_day, :seven]
    end

    task abandoned_cart_job: :environment do
      C::BackgroundJob.process('Abandoned Cart Mailout') do
        Rake::Task['c:mailer:abandoned_cart'].invoke
      end
    end

    task voucher_emails: :environment do
      sales = C::Order::Sale.where(voucher_email_sent: false).where.not(voucher_id: nil)
      sales.each do |sale|
        voucher = sale.product_voucher

        if !voucher || !voucher.start_time || !voucher.end_time
          next
        end

        if voucher.active?
          puts "- mailing voucher code to: #{sale.id}"
          C::OrderMailer.send_voucher_email(sale).deliver_now
          sale.update!(voucher_email_sent: true)
        end
      end
    end

    task voucher_emails_job: :environment do
      C::BackgroundJob.process('Voucher Mailout') do
        Rake::Task['c:mailer:voucher_emails'].invoke
      end
    end
  end
end