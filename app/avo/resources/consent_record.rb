class Avo::Resources::ConsentRecord < Avo::BaseResource
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
    field :subject_token, as: :text
    field :kind, as: :text
    field :granted_at, as: :date_time
    field :revoked_at, as: :date_time
    field :policy_version, as: :text
  end
end
