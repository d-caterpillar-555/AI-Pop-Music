class Post < ApplicationRecord
  enum :status, { draft: "draft", published: "published" }, validate: true

  validates :slug, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/, message: "may contain lowercase letters, numbers and hyphens" }
  validates :title, presence: true, length: { maximum: 160 }

  scope :published, -> { where(status: "published").where(published_at: ..Time.current) }
  scope :recent, -> { order(published_at: :desc) }

  before_validation :stamp_published_at

  def to_param = slug

  private

  def stamp_published_at
    self.published_at ||= Time.current if status == "published"
  end
end
