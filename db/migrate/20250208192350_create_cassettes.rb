class CreateCassettes < ActiveRecord::Migration[8.0]
  def change
    create_table :cassettes do |t|
      t.string :brand
      t.float :kilometres

      t.timestamps
    end
  end
end
