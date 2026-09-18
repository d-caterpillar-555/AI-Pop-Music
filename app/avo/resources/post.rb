class Avo::Resources::Post < Avo::BaseResource
  self.icon = "tabler/outline/ballpen"
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
    field :slug, as: :text
    field :title, as: :text
    field :excerpt, as: :text
    field :body, as: :textarea
    field :status, as: :select, enum: ::Post.statuses
    field :published_at, as: :date_time
  end
end
