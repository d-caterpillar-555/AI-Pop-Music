class ValidateUserConstraints < ActiveRecord::Migration[8.1]
  # Validates the constraints added without validation in
  # 20260918180000_add_profile_fields_to_users. Separate migration, so the
  # locking validation never runs inside the same transaction that added the
  # columns, and so a large table could be validated during a quiet window.
  def change
    validate_check_constraint :users, name: "users_role_known"
    validate_check_constraint :users, name: "users_name_present"
  end
end
