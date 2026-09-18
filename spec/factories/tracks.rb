FactoryBot.define do
  factory :track do
    genre
    sequence(:title) { |n| "Track #{n}" }
    sequence(:slug) { |n| "track-#{n}" }
    status { "published" }
    bpm { 120 }
    duration_ms { 180_000 }
    musical_key { "Am" }
    mood { "steady" }
    language { "English" }
    published_at { Time.current }

    trait :draft do
      status { "draft" }
      published_at { nil }
    end

    trait :not_downloadable do
      downloadable { false }
    end
  end
end
