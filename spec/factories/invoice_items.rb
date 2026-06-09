FactoryBot.define do
  factory :invoice_item do
    invoice
    description { Faker::Commerce.product_name }
    quantity { rand(1.0..10.0).round(2) }
    unit_price_cents { rand(1000..100000) }
    vat_rate { 20.0 }
  end
end