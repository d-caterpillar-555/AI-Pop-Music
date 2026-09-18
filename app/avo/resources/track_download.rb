class Avo::Resources::TrackDownload < Avo::BaseResource
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
    field :track_id, as: :number
    field :license_terms_version, as: :text
    field :ip_hash, as: :text
    field :user, as: :belongs_to
    field :track, as: :belongs_to
  end
end
