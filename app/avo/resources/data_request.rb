class Avo::Resources::DataRequest < Avo::BaseResource
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
    field :user_id, as: :number
    field :kind, as: :select, enum: ::DataRequest.kinds
    field :status, as: :select, enum: ::DataRequest.statuses
    field :requested_at, as: :date_time
    field :completed_at, as: :date_time
    field :user, as: :belongs_to
  end
end
