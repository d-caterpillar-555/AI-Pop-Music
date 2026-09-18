# Append-only by construction: there is no updated_at column, updates are
# refused in Ruby, and the table carries a database trigger that raises on
# UPDATE or DELETE. An audit row that can be edited is not an audit row.
class SubscriptionEvent < ApplicationRecord
  belongs_to :subscription

  validates :kind, inclusion: {
    in: %w[created activated plan_changed genre_added genre_removed renewed past_due canceled reactivated]
  }
  validates :occurred_at, presence: true

  before_update { raise ActiveRecord::ReadOnlyRecord, "subscription_events is append-only" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "subscription_events is append-only" }

  def readonly? = persisted?
end
