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
  end
end