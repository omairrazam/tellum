class AddIndexingToTags < ActiveRecord::Migration
  def change
    #add_column :tags,  :user_id, :integer
    #add_column :tags,  :rating_id, :integer
    add_index :tags, [:user_id]
    add_index :tags, [:rating_id]  end
end
