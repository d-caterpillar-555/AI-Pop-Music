class Avo::Resources::GenerationRun < Avo::BaseResource
  # self.icon = "tabler/outline/users"
  # self.avatar = {
  #   source: :avatar
  # }
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    # field :avatar, as: :avatar
    field :generation_batch_id, as: :number
    field :track_id, as: :number
    field :status, as: :select, enum: ::GenerationRun.statuses
    field :comfy_prompt_id, as: :text
    field :seed, as: :number
    field :error, as: :textarea
    field :started_at, as: :date_time
    field :finished_at, as: :date_time
    field :duration_ms, as: :number
    field :generation_batch, as: :belongs_to
    field :track, as: :belongs_to
  end
end
