class CreateTracks < ActiveRecord::Migration[8.1]
  def change
    create_table :tracks do |t|
      t.references :genre, null: false, foreign_key: true

      t.string :title, null: false
      t.string :slug, null: false
      t.string :status, null: false, default: "draft"
      t.string :artist_name

      t.integer :duration_ms
      t.integer :bpm
      t.string :musical_key
      t.string :mood
      t.string :language

      t.text :lyrics
      t.text :abc_score
      t.text :prompt_style
      t.string :model_id
      t.bigint :seed

      t.boolean :downloadable, null: false, default: true
      t.integer :position, null: false, default: 0
      t.datetime :published_at

      t.timestamps
    end

    add_index :tracks, :slug, unique: true
    add_index :tracks, [ :genre_id, :status ]
    add_index :tracks, :published_at
    add_index :tracks, :position

    add_check_constraint :tracks, "char_length(title) > 0", name: "tracks_title_present"
    add_check_constraint :tracks, "slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'", name: "tracks_slug_format"
    add_check_constraint :tracks, "status IN ('draft', 'published', 'archived')",
      name: "tracks_status_known"
    add_check_constraint :tracks, "duration_ms IS NULL OR duration_ms > 0",
      name: "tracks_duration_positive"
    add_check_constraint :tracks, "bpm IS NULL OR (bpm >= 20 AND bpm <= 400)",
      name: "tracks_bpm_sane"
    add_check_constraint :tracks, "status <> 'published' OR published_at IS NOT NULL",
      name: "tracks_published_has_timestamp"
  end
end
