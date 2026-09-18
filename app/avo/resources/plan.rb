class Avo::Resources::Plan < Avo::BaseResource
  self.icon = "tabler/outline/list"
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
    field :price_cents, as: :number
    field :currency, as: :text
    field :interval, as: :text
    field :genre_limit, as: :number
    field :features, as: :code
    field :position, as: :number
    field :active, as: :boolean
    field :subscriptions, as: :has_many
    field :orders, as: :has_many
  end
end
