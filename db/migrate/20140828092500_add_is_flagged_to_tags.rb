class AddIsFlaggedToTags < ActiveRecord::Migration
  def change
    add_column :tags, :is_flagged, :boolean, default: false
  end
end
