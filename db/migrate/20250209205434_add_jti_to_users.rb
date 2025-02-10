class AddJtiToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :jti, :string
    User.find_each { |user| user.update!(jti: SecureRandom.uuid) }
    change_column_null :users, :jti, false
  end

  def down
    remove_column :users, :jti
  end
end
