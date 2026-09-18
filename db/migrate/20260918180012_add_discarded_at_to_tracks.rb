class AddDiscardedAtToTracks < ActiveRecord::Migration[8.1]
  # The index is built concurrently: `tracks` is a table the catalogue reads on
  # every request, and a plain CREATE INDEX takes a write lock for the duration
  # of the build. DDL transactions are therefore disabled for this migration.
  disable_ddl_transaction!

  def change
    add_column :tracks, :discarded_at, :datetime
    add_index :tracks, :discarded_at, algorithm: :concurrently
  end
end
