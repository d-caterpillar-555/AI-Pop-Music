FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "member#{n}@example.com" }
    name { "Test Member" }
    password { "password1234" }
    password_confirmation { "password1234" }
    terms_accepted_at { Time.current }
    role { "member" }

    trait :editor do
      role { "editor" }
    end

    trait :admin do
      role { "admin" }
    end
  end
end
