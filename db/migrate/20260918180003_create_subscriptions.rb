class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.string :status, null: false, default: "incomplete"
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :canceled_at

      # Gateway plug points. Unused in v1: no provider is integrated, so these
      # stay null until a gateway is added. They exist now because adding them
      # later means a migration on a hot table.
      t.string :provider
      t.string :provider_subscription_id
      t.jsonb :provider_payload, null: false, default: {}

      t.timestamps
    end

    # One live subscription per user. Canceled rows are kept for history and do
    # not block a new subscription.
    add_index :subscriptions, :user_id,
      unique: true,
      where: "status IN ('incomplete', 'active', 'past_due')",
      name: "subscriptions_one_live_per_user"

    add_index :subscriptions, [ :provider, :provider_subscription_id ],
      unique: true,
      where: "provider_subscription_id IS NOT NULL",
      name: "subscriptions_provider_id_unique"

    add_check_constraint :subscriptions,
      "status IN ('incomplete', 'active', 'past_due', 'canceled')",
      name: "subscriptions_status_known"

    add_check_constraint :subscriptions,
      "current_period_end IS NULL OR current_period_start IS NULL " \
      "OR current_period_end > current_period_start",
      name: "subscriptions_period_ordered"

    add_check_constraint :subscriptions,
      "canceled_at IS NULL OR status = 'canceled'",
      name: "subscriptions_canceled_has_status"

    # Append-only history. The subscription row is mutable state; the events are
    # the record of how it got there.
    create_table :subscription_events do |t|
      t.references :subscription, null: false, foreign_key: true
      t.string :kind, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :occurred_at, null: false

      t.datetime :created_at, null: false
    end

    add_index :subscription_events, [ :subscription_id, :occurred_at ]
    add_check_constraint :subscription_events,
      "kind IN ('created', 'activated', 'plan_changed', 'genre_added', " \
      "'genre_removed', 'renewed', 'past_due', 'canceled', 'reactivated')",
      name: "subscription_events_kind_known"

    reversible do |dir|
      dir.up do
        safety_assured do
          execute <<~SQL
            CREATE OR REPLACE FUNCTION prevent_modification() RETURNS trigger AS $$
            BEGIN
              RAISE EXCEPTION 'table % is append-only and cannot be modified', TG_TABLE_NAME;
            END;
            $$ LANGUAGE plpgsql;

            CREATE TRIGGER subscription_events_append_only
              BEFORE UPDATE OR DELETE ON subscription_events
              FOR EACH ROW EXECUTE FUNCTION prevent_modification();
          SQL
        end
      end

      dir.down do
        safety_assured do
          execute <<~SQL
            DROP TRIGGER IF EXISTS subscription_events_append_only ON subscription_events;
          SQL
        end
      end
    end
  end
end
