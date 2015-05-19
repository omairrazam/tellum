class AddIsPublicProfileToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_public_profile, :boolean, default: true
  end
end
