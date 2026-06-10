FactoryBot.define do
  factory :organization do
    name { Faker::Company.name }
    email { Faker::Internet.email }
    invoice_prefix { "FAC" }
    phone { Faker::PhoneNumber.phone_number }
    address { Faker::Address.street_address }
    city { Faker::Address.city }
    zip_code { Faker::Address.zip_code }
    country { "FR" }
    siren { Faker::Number.number(digits: 9).to_s }
    siret { Faker::Number.number(digits: 14).to_s }
    vat_number { "FR#{Faker::Number.number(digits: 11)}" }
    legal_form { "SAS" }
    capital { 10000.00 }
  end
end
