class Page < ApplicationRecord
  enum :status, { draft: "draft", published: "published" }, validate: true

  validates :slug, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/, message: "may contain lowercase letters, numbers and hyphens" }
  validates :title, presence: true

  scope :published, -> { where(status: "published") }
  scope :ordered, -> { order(:slug) }

  def to_param = slug
end
