FactoryBot.define do
  factory :plan do
    sequence(:name) { |n| "Plan #{n}" }
    sequence(:slug) { |n| "plan-#{n}" }
    price_cents { 500 }
    genre_limit { 1 }
    interval { "month" }
    currency { "USD" }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
