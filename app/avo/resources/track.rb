class Avo::Resources::Track < Avo::BaseResource
  self.title = :title
  self.includes = [ :genre ]

  def fields
    field :id, as: :id
    field :title, as: :text
    field :slug, as: :text, readonly: true, only_on: :show
    field :genre, as: :belongs_to
    field :status, as: :select, enum: ::Track.statuses
    field :published_at, as: :date_time
    field :downloadable, as: :boolean

    field :artist_name, as: :text
    field :bpm, as: :number
    field :musical_key, as: :text
    field :mood, as: :text
    field :language, as: :text
    field :duration_ms, as: :number, help: "Milliseconds. Set once the master is measured."
    field :position, as: :number

    field :audio, as: :file, help: "Full-length master. Private; served only to entitled members."
    field :preview, as: :file, help: "Public excerpt, 20-30 seconds."
    field :artwork, as: :file

    field :lyrics, as: :textarea, only_on: [ :show, :edit ]
    field :abc_score, as: :textarea, only_on: [ :show, :edit ], help: "YuE2's symbolic score, as recorded by the run."
    field :prompt_style, as: :textarea, only_on: [ :show, :edit ]
    field :model_id, as: :text, readonly: true, only_on: :show
    field :seed, as: :number, readonly: true, only_on: :show

    field :track_downloads, as: :has_many, only_on: :show
    field :discarded_at, as: :date_time, readonly: true, only_on: :show
    field :created_at, as: :date_time, readonly: true, only_on: :show
  end
end
