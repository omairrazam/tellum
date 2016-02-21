class AddIsBoxLockedToRatings < ActiveRecord::Migration
  def change
    add_column :ratings, :is_box_locked, :boolean, default: false
  end
end
