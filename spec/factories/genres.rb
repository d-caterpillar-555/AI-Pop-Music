FactoryBot.define do
  factory :genre do
    sequence(:name) { |n| "Genre #{n}" }
    sequence(:position) { |n| n }
    description { "A synthetic genre used in specs." }
    published { true }

    trait :unpublished do
      published { false }
    end
  end
end
