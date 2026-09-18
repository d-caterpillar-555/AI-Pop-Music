class Avo::Resources::User < Avo::BaseResource
  self.icon = "tabler/outline/users"
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
    field :email, as: :text
    field :name, as: :text
    field :role, as: :select, enum: ::User.roles
    field :terms_accepted_at, as: :date_time
    field :sign_in_count, as: :number
    field :current_sign_in_at, as: :date_time
    field :last_sign_in_at, as: :date_time
    field :current_sign_in_ip, as: :text
    field :last_sign_in_ip, as: :text
    field :subscriptions, as: :has_many
    field :orders, as: :has_many
    field :track_downloads, as: :has_many
    field :data_requests, as: :has_many
    field :genre_entitlements, as: :has_many, through: :subscriptions
    field :generation_batches, as: :has_many
  end
end
