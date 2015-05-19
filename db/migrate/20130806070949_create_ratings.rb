class CreateRatings < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.string :rating
      t.integer :tag_id
      t.string :sub_rating
      t.string :comment
      t.boolean :is_anonymous_rating
      t.boolean :is_post_to_wall
      t.timestamps
    end
  end
end
