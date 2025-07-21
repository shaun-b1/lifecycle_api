class AddServicesTable < ActiveRecord::Migration[8.0]
  def change
    create_table :services do |t|
      t.references :bicycle, null: false, foreign_key: true
      t.datetime :performed_at, null: false
      t.text :notes, null: false
      t.string :service_type, null: false

      t.timestamps
    end

    add_index :services, [:bicycle_id, :performed_at]
    add_index :services, :service_type
    add_index :services, :performed_at
  end
end
