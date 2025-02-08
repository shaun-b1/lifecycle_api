class AddComponentsForeignKeysToBicycles < ActiveRecord::Migration[8.0]
  def change
    add_reference :tires, :bicycle, null: false, foreign_key: true
    add_reference :brakepads, :bicycle, null: false, foreign_key: true
    add_reference :cassettes, :bicycle, null: false, foreign_key: true
    add_reference :chainrings, :bicycle, null: false, foreign_key: true
  end
end
