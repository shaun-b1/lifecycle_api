class RenameBicycleChainsToChains < ActiveRecord::Migration[8.0]
  def change
    rename_table :bicycle_chains, :chains
  end
end
