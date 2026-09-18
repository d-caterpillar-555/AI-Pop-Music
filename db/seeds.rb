# Seed data.
#
# Everything here is synthetic and labelled as such. The tracks are METADATA
# PLACEHOLDERS for developing the catalogue UI: they carry no audio, no model id
# and no seed, because inventing provenance for a track that was never generated
# would be a lie in the catalogue. Real audio arrives from a GenerationBatch once
# the YuE2 models are in place.
#
# Idempotent: safe to run repeatedly.

puts "Seeding AI Pop Music"

# --- Plans -------------------------------------------------------------------
plans = [
  { name: "Starter", slug: "starter", price_cents: 500, genre_limit: 1, position: 1,
    features: { "includes" => [ "1 genre of your choice", "Unlimited downloads within it", "48 kHz stereo masters", "Commercial licence" ] } },
  { name: "Pro", slug: "pro", price_cents: 1500, genre_limit: 3, position: 2,
    features: { "includes" => [ "3 genres of your choice", "Unlimited downloads within them", "48 kHz stereo masters", "Commercial licence" ] } },
  { name: "Studio", slug: "studio", price_cents: 5000, genre_limit: 10, position: 3,
    features: { "includes" => [ "10 genres of your choice", "Unlimited downloads within them", "48 kHz stereo masters", "Commercial licence", "Priority on custom requests" ] } }
]

plans.each do |attributes|
  plan = Plan.find_or_initialize_by(slug: attributes[:slug])
  plan.update!(attributes)
end
puts "  plans: #{Plan.count}"

# --- Genres ------------------------------------------------------------------
genres = [
  { name: "Synthwave", position: 1, description: "Retro-futurist instrumentals: gated drums, wide analog pads, neon basslines." },
  { name: "Lo-fi", position: 2, description: "Dusty, unhurried beats with soft keys. Made for talking over." },
  { name: "Cinematic", position: 3, description: "Orchestral builds and tension beds for trailers, docs and drama." },
  { name: "Afrobeat", position: 4, description: "Percussive, bright and dance-forward, with room for vocal hooks." },
  { name: "Hyperpop", position: 5, description: "Loud, fast and deliberately synthetic. Pitch-shifted and maximal." },
  { name: "Ambient", position: 6, description: "Slow-moving textures for focus, meditation and background." }
]

genres.each do |attributes|
  genre = Genre.find_or_initialize_by(slug: attributes[:name].parameterize)
  genre.update!(attributes.merge(published: true))
end
puts "  genres: #{Genre.count}"

# --- Accounts ----------------------------------------------------------------
accounts = [
  { email: "admin@example.com", name: "Catalogue Admin", role: "admin" },
  { email: "editor@example.com", name: "Catalogue Editor", role: "editor" },
  { email: "member@example.com", name: "Demo Member", role: "member" }
]

accounts.each do |attributes|
  user = User.find_or_initialize_by(email: attributes[:email])
  user.assign_attributes(
    name: attributes[:name],
    role: attributes[:role],
    terms_accepted_at: Time.current
  )
  user.password = "password1234" if user.new_record?
  user.save!
end
puts "  users: #{User.count} (admin/editor/member @example.com, password: password1234)"

# --- Tracks ------------------------------------------------------------------
demo_tracks = {
  "synthwave" => [
    [ "Neon Rain", 110, "F#m", 185_000, "night drive" ],
    [ "Chrome Coast", 104, "Am", 201_000, "optimistic" ],
    [ "Midnight Freeway", 118, "Dm", 176_000, "urgent" ]
  ],
  "lo-fi" => [
    [ "Paper Lantern", 82, "Cmaj", 168_000, "calm" ],
    [ "Second Coffee", 88, "Gmaj", 154_000, "warm" ],
    [ "Rain on Glass", 76, "Em", 192_000, "melancholic" ]
  ],
  "cinematic" => [
    [ "First Light", 92, "Dmaj", 214_000, "hopeful" ],
    [ "The Long Ascent", 78, "Am", 238_000, "tense" ]
  ],
  "afrobeat" => [
    [ "Lagos Morning", 102, "Fmaj", 196_000, "bright" ],
    [ "Palm Wine", 108, "Bbmaj", 182_000, "playful" ]
  ],
  "hyperpop" => [
    [ "Candy Static", 160, "G#m", 148_000, "chaotic" ],
    [ "Sugar Rush", 172, "Bm", 141_000, "euphoric" ]
  ],
  "ambient" => [
    [ "Slow Ice", 60, "Cmaj", 312_000, "still" ],
    [ "Long Horizon", 64, "Fmaj", 288_000, "vast" ]
  ]
}

demo_tracks.each do |genre_slug, tracks|
  genre = Genre.find_by!(slug: genre_slug)

  tracks.each_with_index do |(title, bpm, key, duration_ms, mood), index|
    track = Track.find_or_initialize_by(slug: title.parameterize)
    track.assign_attributes(
      genre: genre,
      title: title,
      bpm: bpm,
      musical_key: key,
      duration_ms: duration_ms,
      mood: mood,
      language: "English",
      status: "published",
      published_at: track.published_at || (index + 1).days.ago,
      position: index
    )
    track.save!
  end
end
puts "  tracks: #{Track.count} published (metadata placeholders - no audio attached yet)"

puts
puts "Note: seeded tracks carry no audio. Generate real tracks with a"
puts "GenerationBatch in /admin once the YuE2 ComfyUI models have downloaded."
