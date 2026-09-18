class CreatePlatformTables < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.references :user, null: true, foreign_key: true
      t.string :action, null: false
      t.string :subject_type
      t.bigint :subject_id
      t.string :ip_hash
      t.jsonb :metadata, null: false, default: {}

      t.datetime :created_at, null: false
    end

    add_index :audit_events, [ :subject_type, :subject_id ]
    add_index :audit_events, [ :user_id, :created_at ]
    add_check_constraint :audit_events, "char_length(action) > 0",
      name: "audit_events_action_present"

    create_table :consent_records do |t|
      t.string :subject_token, null: false
      t.string :kind, null: false
      t.datetime :granted_at, null: false
      t.datetime :revoked_at
      t.string :policy_version, null: false

      t.datetime :created_at, null: false
    end

    add_index :consent_records, [ :subject_token, :kind ]
    add_check_constraint :consent_records,
      "kind IN ('analytics', 'marketing', 'cookies', 'terms')",
      name: "consent_records_kind_known"
    add_check_constraint :consent_records,
      "revoked_at IS NULL OR revoked_at >= granted_at",
      name: "consent_records_revocation_after_grant"

    create_table :data_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :requested_at, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_check_constraint :data_requests, "kind IN ('export', 'deletion')",
      name: "data_requests_kind_known"
    add_check_constraint :data_requests,
      "status IN ('pending', 'processing', 'completed', 'rejected')",
      name: "data_requests_status_known"
    add_check_constraint :data_requests,
      "status <> 'completed' OR completed_at IS NOT NULL",
      name: "data_requests_completed_has_timestamp"

    create_table :pages do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.text :body
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :pages, :slug, unique: true
    add_check_constraint :pages, "status IN ('draft', 'published')",
      name: "pages_status_known"

    create_table :posts do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.string :excerpt
      t.text :body
      t.string :status, null: false, default: "draft"
      t.datetime :published_at

      t.timestamps
    end

    add_index :posts, :slug, unique: true
    add_index :posts, :published_at
    add_check_constraint :posts, "status IN ('draft', 'published')",
      name: "posts_status_known"
    add_check_constraint :posts,
      "status <> 'published' OR published_at IS NOT NULL",
      name: "posts_published_has_timestamp"

    create_table :redirects do |t|
      t.string :from_path, null: false
      t.string :to_path, null: false

      t.timestamps
    end

    add_index :redirects, :from_path, unique: true
    add_check_constraint :redirects, "from_path LIKE '/%' AND to_path LIKE '/%'",
      name: "redirects_paths_absolute"

    create_table :newsletter_subscribers do |t|
      t.string :email, null: false
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index :newsletter_subscribers, :email, unique: true
    add_check_constraint :newsletter_subscribers,
      "email ~* '^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$'",
      name: "newsletter_subscribers_email_shape"

    reversible do |dir|
      dir.up do
        safety_assured do
          execute <<~SQL
            CREATE OR REPLACE FUNCTION prevent_modification() RETURNS trigger AS $$
            BEGIN
              RAISE EXCEPTION 'table % is append-only and cannot be modified', TG_TABLE_NAME;
            END;
            $$ LANGUAGE plpgsql;

            CREATE TRIGGER consent_records_append_only
              BEFORE UPDATE OR DELETE ON consent_records
              FOR EACH ROW EXECUTE FUNCTION prevent_modification();
          SQL
        end
      end

      dir.down do
        safety_assured do
          execute <<~SQL
            DROP TRIGGER IF EXISTS consent_records_append_only ON consent_records;
          SQL
        end
      end
    end
  end
end
