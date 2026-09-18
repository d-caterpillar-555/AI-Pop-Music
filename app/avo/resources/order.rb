class Avo::Resources::Order < Avo::BaseResource
  self.icon = "tabler/outline/shopping-cart"
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
    field :number, as: :text
    field :public_token, as: :text
    field :amount_cents, as: :number
    field :currency, as: :text
    field :status, as: :select, enum: ::Order.statuses
    field :provider, as: :text
    field :provider_order_id, as: :text
    field :provider_payload, as: :code
    field :placed_at, as: :date_time
    field :paid_at, as: :date_time
    field :user, as: :belongs_to
    field :plan, as: :belongs_to
  end
end
