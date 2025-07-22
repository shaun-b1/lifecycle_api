class CreateMaintenanceActions < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenance_actions do |t|
      t.references :service, null: false, foreign_key: true
      t.string :component_type
      t.text :action_performed
      t.text :notes

      t.timestamps
    end
  end
end
