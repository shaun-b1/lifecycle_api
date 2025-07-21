class CreateComponentReplacements < ActiveRecord::Migration[8.0]
  def change
    create_table :component_replacements do |t|
      t.references :service, null: false, foreign_key: true
      t.string :component_type, null: false
      t.json :old_component_specs
      t.json :new_component_specs, null: false
      t.text :reason, null: false
      t.text :installation_notes

      t.timestamps
    end

    add_index :component_replacements, [:service_id, :component_type]
    add_index :component_replacements, :component_type
  end
end