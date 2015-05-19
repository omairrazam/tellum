class ChangeCommentTypeInRatings < ActiveRecord::Migration
  def up
    change_column :ratings, :comment, :text
  end

  def down
    change_column :ratings, :comment, :string
  end
end
