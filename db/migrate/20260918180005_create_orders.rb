class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true

      t.string :number, null: false
      t.string :public_token, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "USD"
      t.string :status, null: false, default: "awaiting_payment"

      t.string :provider
      t.string :provider_order_id
      t.jsonb :provider_payload, null: false, default: {}

      t.datetime :placed_at, null: false
      t.datetime :paid_at

      t.timestamps
    end

    add_index :orders, :number, unique: true
    add_index :orders, :public_token, unique: true
    add_index :orders, :status
    add_index :orders, [ :provider, :provider_order_id ],
      unique: true,
      where: "provider_order_id IS NOT NULL",
      name: "orders_provider_id_unique"

    add_check_constraint :orders, "amount_cents > 0", name: "orders_amount_positive"
    add_check_constraint :orders, "currency ~ '^[A-Z]{3}$'", name: "orders_currency_iso"
    add_check_constraint :orders,
      "status IN ('awaiting_payment', 'paid', 'refunded', 'canceled')",
      name: "orders_status_known"

    # A paid order without a payment time is a state the application must never
    # be able to represent.
    add_check_constraint :orders,
      "status <> 'paid' OR paid_at IS NOT NULL",
      name: "orders_paid_has_timestamp"

    # The public token is the only way a guest sees an order, so it must not be
    # guessable by length or shape.
    add_check_constraint :orders,
      "char_length(public_token) >= 24",
      name: "orders_public_token_long_enough"
  end
end
