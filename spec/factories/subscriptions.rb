FactoryBot.define do
  factory :subscription do
    user
    plan
    status { "incomplete" }

    trait :active do
      status { "active" }
      current_period_start { 1.day.ago }
      current_period_end { 1.month.from_now }
    end

    trait :canceled do
      status { "canceled" }
      canceled_at { Time.current }
    end
  end
end
