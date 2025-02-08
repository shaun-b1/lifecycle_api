class CreateBrakepads < ActiveRecord::Migration[8.0]
  def change
    create_table :brakepads do |t|
      t.string :brand
      t.float :kilometres

      t.timestamps
    end
  end
end
