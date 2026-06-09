FactoryBot.define do
  factory :client do
    organization
    name { Faker::Company.name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
    address { Faker::Address.street_address }
    city { Faker::Address.city }
    zip_code { Faker::Address.zip_code }
    country { "FR" }
    siret { Faker::Number.number(digits: 14).to_s }
    vat_number { "FR#{Faker::Number.number(digits: 11)}" }
    client_type { :professional }
  end
end
