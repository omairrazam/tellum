class ChangeTagDescriptionTypeInTags < ActiveRecord::Migration
  def up
    change_column :tags, :tag_description, :text
  end

  def down
    change_column :tags, :tag_description, :string
  end
end
