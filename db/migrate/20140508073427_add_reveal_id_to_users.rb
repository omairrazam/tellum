class AddRevealIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :reveal_id, :integer
  end
end
