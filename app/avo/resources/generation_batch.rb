class Avo::Resources::GenerationBatch < Avo::BaseResource
  self.title = :name
  self.includes = [ :genre ]

  def fields
    field :id, as: :id
    field :name, as: :text
    field :genre, as: :belongs_to
    field :status, as: :select, enum: ::GenerationBatch.statuses, readonly: true
    field :requested_count, as: :number
    field :steps, as: :number
    field :cot, as: :select, options: { "off" => "off", "melody" => "melody", "full" => "full" }
    field :prompt_style, as: :textarea, help: "Genre, instruments, vocal character, language, tempo."
    field :lyrics, as: :textarea, help: "Section tags such as [Verse] and [Chorus]; leave blank for an instrumental."
    field :progress, as: :text, readonly: true, only_on: [ :index, :show ]
    field :created_by, as: :belongs_to
    field :generation_runs, as: :has_many
    field :created_at, as: :date_time, readonly: true, only_on: :show
  end

  def actions
    [ Avo::Actions::QueueGenerationBatch ]
  end
end
