class Avo::Resources::Genre < Avo::BaseResource
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
    field :name, as: :text
    field :slug, as: :text
    field :description, as: :textarea
    field :position, as: :number
    field :published, as: :boolean
    field :artwork, as: :file
    field :tracks, as: :has_many
    field :genre_entitlements, as: :has_many
  end
end
