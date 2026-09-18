class Avo::Resources::Page < Avo::BaseResource
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
    field :slug, as: :text
    field :title, as: :text
    field :body, as: :textarea
    field :status, as: :select, enum: ::Page.statuses
  end
end
