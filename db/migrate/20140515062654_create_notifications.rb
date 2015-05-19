class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :user_id
      t.integer :tag_id
      t.integer :rating_id
      t.integer :comment_id
      t.integer :reveal_id
      t.boolean :status
      t.string  :object_name
      t.timestamps
    end
  end
end
