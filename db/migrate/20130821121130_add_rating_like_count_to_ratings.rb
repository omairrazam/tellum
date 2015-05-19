class AddRatingLikeCountToRatings < ActiveRecord::Migration
  def change
    add_column :ratings, :rating_like_count, :integer, default: 0
  end
end
