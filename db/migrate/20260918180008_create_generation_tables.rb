class CreateGenerationTables < ActiveRecord::Migration[8.1]
  def change
    create_table :generation_batches do |t|
      t.references :genre, null: false, foreign_key: true
      t.references :created_by, null: true, foreign_key: { to_table: :users }

      t.string :name, null: false
      t.text :prompt_style, null: false
      t.text :lyrics
      t.string :cot, null: false, default: "off"
      t.integer :steps, null: false, default: 32
      t.integer :requested_count, null: false, default: 1
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    add_index :generation_batches, :status

    add_check_constraint :generation_batches, "char_length(name) > 0",
      name: "generation_batches_name_present"
    add_check_constraint :generation_batches, "char_length(prompt_style) > 0",
      name: "generation_batches_prompt_present"
    add_check_constraint :generation_batches, "cot IN ('off', 'melody', 'full')",
      name: "generation_batches_cot_known"
    add_check_constraint :generation_batches, "steps > 0",
      name: "generation_batches_steps_positive"
    add_check_constraint :generation_batches, "requested_count > 0",
      name: "generation_batches_count_positive"
    add_check_constraint :generation_batches,
      "status IN ('draft', 'queued', 'running', 'completed', 'canceled')",
      name: "generation_batches_status_known"

    create_table :generation_runs do |t|
      t.references :generation_batch, null: false, foreign_key: true
      # Set when the run produced a track. Null for failed/canceled runs.
      t.references :track, null: true, foreign_key: true

      t.string :status, null: false, default: "queued"
      t.string :comfy_prompt_id
      t.bigint :seed
      t.text :error
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :duration_ms

      t.timestamps
    end

    add_index :generation_runs, :status
    add_index :generation_runs, :comfy_prompt_id,
      unique: true,
      where: "comfy_prompt_id IS NOT NULL",
      name: "generation_runs_comfy_prompt_unique"

    add_check_constraint :generation_runs,
      "status IN ('queued', 'running', 'succeeded', 'failed', 'canceled')",
      name: "generation_runs_status_known"
    add_check_constraint :generation_runs,
      "finished_at IS NULL OR started_at IS NULL OR finished_at >= started_at",
      name: "generation_runs_times_ordered"
    add_check_constraint :generation_runs,
      "status <> 'failed' OR error IS NOT NULL",
      name: "generation_runs_failed_has_error"
    add_check_constraint :generation_runs,
      "duration_ms IS NULL OR duration_ms >= 0",
      name: "generation_runs_duration_non_negative"
  end
end
