class CreateTrackDownloads < ActiveRecord::Migration[8.1]
  def change
    # The license audit trail. This is the table that answers "who is allowed to
    # use which track, under which terms" after the fact, so it is append-only
    # by trigger: an audit row that can be edited is not an audit row.
    create_table :track_downloads do |t|
      t.references :user, null: false, foreign_key: true
      t.references :track, null: false, foreign_key: true
      t.string :license_terms_version, null: false
      t.string :ip_hash

      t.datetime :created_at, null: false
    end

    add_index :track_downloads, [ :user_id, :created_at ]
    add_index :track_downloads, [ :track_id, :created_at ]

    add_check_constraint :track_downloads, "char_length(license_terms_version) > 0",
      name: "track_downloads_license_version_present"

    reversible do |dir|
      dir.up do
        safety_assured do
          execute <<~SQL
            CREATE OR REPLACE FUNCTION prevent_modification() RETURNS trigger AS $$
            BEGIN
              RAISE EXCEPTION 'table % is append-only and cannot be modified', TG_TABLE_NAME;
            END;
            $$ LANGUAGE plpgsql;

            CREATE TRIGGER track_downloads_append_only
              BEFORE UPDATE OR DELETE ON track_downloads
              FOR EACH ROW EXECUTE FUNCTION prevent_modification();
          SQL
        end
      end

      dir.down do
        safety_assured do
          execute <<~SQL
            DROP TRIGGER IF EXISTS track_downloads_append_only ON track_downloads;
          SQL
        end
      end
    end
  end
end
