class AddIsFollowingToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_following, :boolean, default: false
  end
end
