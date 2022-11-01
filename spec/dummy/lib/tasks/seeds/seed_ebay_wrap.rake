# frozen_string_literal: true

task seed_ebay_wrap: :environment do
  C::Product::Wrap.create!(
    name: "Really bad wrap",
    wrap: "
              <div style='border:5px solid green'>
              <h1> [{PRODUCT_LISTING_TITLE}]  </h1>
              <p>[{PRODUCT_DESCRIPTION}]</p>
              <img  src='[{PRODUCT_IMAGE_1}]'> </div>
              <img src='[{PRODUCT_IMAGE_2}]'>
              <img src='[{PRODUCT_IMAGE_3}]'>
              <img src='[{PRODUCT_IMAGE_4}]'>
              </div>
          "
  )
end
