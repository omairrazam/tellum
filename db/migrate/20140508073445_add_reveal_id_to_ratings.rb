class AddRevealIdToRatings < ActiveRecord::Migration
  def change
    add_column :ratings, :reveal_id, :integer
  end
end
