class CreateGenres < ActiveRecord::Migration[8.1]
  def change
    create_table :genres do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: false

      t.timestamps
    end

    add_index :genres, :slug, unique: true
    add_index :genres, :position

    add_check_constraint :genres, "char_length(name) > 0", name: "genres_name_present"
    add_check_constraint :genres, "slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'", name: "genres_slug_format"
  end
end
