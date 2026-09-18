class Redirect < ApplicationRecord
  validates :from_path, presence: true, uniqueness: true
  validates :to_path, presence: true
  validate :paths_are_absolute

  private

  def paths_are_absolute
    errors.add(:from_path, "must start with /") unless from_path&.start_with?("/")
    errors.add(:to_path, "must start with /") unless to_path&.start_with?("/")
  end
end
