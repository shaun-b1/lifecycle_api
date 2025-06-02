class CreateKilometreLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :kilometre_logs do |t|
      t.references :trackable, polymorphic: true, null: false
      t.string :event_type, null: false
      t.float :previous_value, null: false, default: 0
      t.float :new_value, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :kilometre_logs, [ :trackable_type, :trackable_id, :created_at ]
  end
end
