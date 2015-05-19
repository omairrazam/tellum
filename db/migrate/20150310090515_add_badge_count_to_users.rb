class AddBadgeCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :badge_count, :integer, default: 0
  end
end
