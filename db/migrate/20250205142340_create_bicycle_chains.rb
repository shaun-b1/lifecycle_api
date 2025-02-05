class CreateBicycleChains < ActiveRecord::Migration[8.0]
  def change
    create_table :bicycle_chains do |t|
      t.string :brand
      t.float :kilometres_ridden
      t.references :bicycle, null: false, foreign_key: true

      t.timestamps
    end
  end
end
