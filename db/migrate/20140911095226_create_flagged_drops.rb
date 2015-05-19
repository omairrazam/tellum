class CreateFlaggedDrops < ActiveRecord::Migration
  def change
    create_table :flagged_drops do |t|
      t.boolean :is_flagged
      t.integer :user_id
      t.integer :rating_id

      t.timestamps
    end
  end
end
