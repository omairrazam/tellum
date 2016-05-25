class CreateRatingHideBies < ActiveRecord::Migration
  def change
    create_table :rating_hide_bies do |t|
      t.references :rating
      t.references :user

      t.timestamps
    end
    add_index :rating_hide_bies, :rating_id
    add_index :rating_hide_bies, :user_id
  end
end
