class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string, null: false, default: ""
    add_column :users, :role, :string, null: false, default: "member"
    add_column :users, :terms_accepted_at, :datetime

    add_column :users, :sign_in_count, :integer, null: false, default: 0
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string

    # Added without validation because the table is live and a validating check
    # takes a lock while it scans every row. 20260918180011 validates them.
    add_check_constraint :users, "role IN ('member', 'editor', 'admin')",
      name: "users_role_known", validate: false
    add_check_constraint :users, "char_length(name) > 0",
      name: "users_name_present", validate: false
  end
end
