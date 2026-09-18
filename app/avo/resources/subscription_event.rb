class Avo::Resources::SubscriptionEvent < Avo::BaseResource
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
    field :kind, as: :text
    field :payload, as: :code
    field :occurred_at, as: :date_time
    field :subscription, as: :belongs_to
  end
end
