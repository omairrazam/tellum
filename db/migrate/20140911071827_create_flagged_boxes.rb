class CreateFlaggedBoxes < ActiveRecord::Migration
  def change
    create_table :flagged_boxes do |t|
      t.boolean :is_flagged
      t.integer :user_id
      t.integer :tag_id

      t.timestamps
    end
  end
end
