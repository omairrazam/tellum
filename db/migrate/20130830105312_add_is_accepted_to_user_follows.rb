class AddIsAcceptedToUserFollows < ActiveRecord::Migration
  def change
    add_column :user_follows, :is_accepted, :boolean
  end
end
