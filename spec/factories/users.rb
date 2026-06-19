FactoryBot.define do
  factory :user do
    organization
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    password { "password123" }
    role { :member }

    trait :owner do
      role { :owner }
    end

    trait :admin do
      role { :admin }
    end

    trait :without_org do
      organization { nil }
    end
  end
end
