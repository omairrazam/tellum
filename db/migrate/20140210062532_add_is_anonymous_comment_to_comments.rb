class AddIsAnonymousCommentToComments < ActiveRecord::Migration
  def change
    add_column :comments, :is_anonymous_comment, :boolean, default: false
  end
end
