class GenreEntitlement < ApplicationRecord
  belongs_to :subscription
  belongs_to :genre

  validates :genre_id, uniqueness: { scope: :subscription_id }

  # The DB unique index is the real guarantee; this validation exists so the
  # user sees a message instead of a RecordNotUnique.
  after_create_commit :record_event

  scope :for_genre, ->(genre) { where(genre_id: genre) }

  private

  def record_event
    subscription.subscription_events.create!(
      kind: "genre_added",
      occurred_at: Time.current,
      payload: { genre_id: genre_id, genre_slug: genre.slug }
    )
  end
end
