class AddIsApprovedToUserFollow < ActiveRecord::Migration
  def change
    add_column :user_follows, :is_approved, :boolean, default: true
  end
end
