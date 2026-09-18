FactoryBot.define do
  factory :generation_batch do
    genre
    name { "Spec batch" }
    prompt_style { "warm acoustic pop, clear female vocal, piano" }
    lyrics { "[Verse]\nShine through the night" }
    cot { "off" }
    steps { 32 }
    requested_count { 1 }
    status { "draft" }

    trait :queued do
      status { "queued" }
    end
  end

  factory :generation_run do
    generation_batch
    status { "queued" }
    seed { 12_345 }
  end
end
