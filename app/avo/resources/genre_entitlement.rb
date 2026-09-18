class Avo::Resources::GenreEntitlement < Avo::BaseResource
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
    field :subscription_id, as: :number
    field :genre_id, as: :number
    field :subscription, as: :belongs_to
    field :genre, as: :belongs_to
  end
end
