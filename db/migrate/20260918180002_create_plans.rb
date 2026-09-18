class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :price_cents, null: false
      t.string :currency, null: false, default: "USD"
      t.string :interval, null: false, default: "month"
      t.integer :genre_limit, null: false
      t.jsonb :features, null: false, default: {}
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :plans, :slug, unique: true
    add_index :plans, :position

    add_check_constraint :plans, "char_length(name) > 0", name: "plans_name_present"
    add_check_constraint :plans, "slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'", name: "plans_slug_format"
    add_check_constraint :plans, "price_cents > 0", name: "plans_price_positive"
    add_check_constraint :plans, "genre_limit > 0", name: "plans_genre_limit_positive"
    add_check_constraint :plans, "interval IN ('month', 'year')", name: "plans_interval_known"
    add_check_constraint :plans, "currency ~ '^[A-Z]{3}$'", name: "plans_currency_iso"
  end
end
