class AddIsFlaggedToRatings < ActiveRecord::Migration
  def change
    add_column :ratings, :is_flagged, :boolean, default: false
  end
end
