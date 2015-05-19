class AddIsLikeToUserRatings < ActiveRecord::Migration
  def change
    add_column :user_ratings, :is_like, :boolean, default: false
  end
end
