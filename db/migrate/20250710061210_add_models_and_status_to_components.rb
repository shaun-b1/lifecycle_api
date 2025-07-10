class AddModelsAndStatusToComponents < ActiveRecord::Migration[8.0]
  def change
    %w[chains cassettes chainrings tires brakepads].each do |table|
      add_column table, :model, :string, default: 'Unknown', null: false
      add_column table, :status, :string, default: 'active', null: false
      add_column table, :replaced_at, :datetime

      add_index table, :status
      add_index table, [ :bicycle_id, :status ]
    end
  end
end
