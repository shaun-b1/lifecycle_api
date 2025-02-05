class AddKilometresToBicycles < ActiveRecord::Migration[8.0]
  def change
    add_column :bicycles, :kilometres, :float
  end
end
