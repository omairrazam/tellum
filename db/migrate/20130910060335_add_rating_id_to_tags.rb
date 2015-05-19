class AddRatingIdToTags < ActiveRecord::Migration
  def change
    add_column :tags, :rating_id, :integer
  end
end
