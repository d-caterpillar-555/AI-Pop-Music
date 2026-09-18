class CreateGenreEntitlements < ActiveRecord::Migration[8.1]
  def change
    create_table :genre_entitlements do |t|
      t.references :subscription, null: false, foreign_key: true
      t.references :genre, null: false, foreign_key: true

      t.timestamps
    end

    add_index :genre_entitlements, [ :subscription_id, :genre_id ],
      unique: true,
      name: "genre_entitlements_unique_per_subscription"

    # Note: the plan's genre_limit cannot be expressed as a CHECK constraint
    # (it lives on another table). It is enforced in Subscription::AddGenre and
    # covered by specs; this index guarantees no duplicate grant.
  end
end
