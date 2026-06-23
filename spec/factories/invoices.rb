FactoryBot.define do
  factory :invoice do
    organization
    client
    number { "FAC-#{Faker::Number.unique.number(digits: 6)}" }
    issue_date { Date.today }
    due_date { 30.days.from_now.to_date }
    status { :draft }
    currency { "EUR" }
    subject { Faker::Lorem.sentence }

    trait :finalized do
      status { :finalized }
      finalized_at { Time.current }
    end

    trait :sent do
      status { :sent }
      finalized_at { 1.day.ago }
      sent_at { Time.current }
    end
  end
end
