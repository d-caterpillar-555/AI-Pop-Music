class Avo::Resources::AuditEvent < Avo::BaseResource
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
    field :action, as: :text
    field :subject_type, as: :text
    field :subject_id, as: :number
    field :ip_hash, as: :text
    field :metadata, as: :code
    field :user, as: :belongs_to
  end
end
