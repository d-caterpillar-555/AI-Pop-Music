class Avo::Resources::Subscription < Avo::BaseResource
  self.icon = "tabler/outline/credit-card"
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
    field :user_id, as: :number
    field :plan_id, as: :number
    field :status, as: :select, enum: ::Subscription.statuses
    field :current_period_start, as: :date_time
    field :current_period_end, as: :date_time
    field :canceled_at, as: :date_time
    field :provider, as: :text
    field :provider_subscription_id, as: :text
    field :provider_payload, as: :code
    field :user, as: :belongs_to
    field :plan, as: :belongs_to
    field :genre_entitlements, as: :has_many
    field :subscription_events, as: :has_many
    field :genres, as: :has_many, through: :genre_entitlements
    field :orders, as: :belongs_to
  end
end
