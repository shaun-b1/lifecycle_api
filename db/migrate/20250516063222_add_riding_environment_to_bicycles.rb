class AddRidingEnvironmentToBicycles < ActiveRecord::Migration[8.0]
  def change
    add_column :bicycles, :terrain, :string
    add_column :bicycles, :weather, :string
    add_column :bicycles, :particulate, :string
  end
end
