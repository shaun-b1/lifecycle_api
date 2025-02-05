class RenameKilometresRiddenInChains < ActiveRecord::Migration[8.0]
  def change
    rename_column :chains, :kilometres_ridden, :kilometres
  end
end
