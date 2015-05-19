class AddUpdatedTimeToTags < ActiveRecord::Migration
  def change
    add_column :tags, :updated_time, :datetime
  end
end
