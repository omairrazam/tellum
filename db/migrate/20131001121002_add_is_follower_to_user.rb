class AddIsFollowerToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_follower, :boolean, default: false
  end
end
