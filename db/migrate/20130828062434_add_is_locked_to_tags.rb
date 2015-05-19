class AddIsLockedToTags < ActiveRecord::Migration
  def change
    add_column :tags, :is_locked, :boolean
  end
end
