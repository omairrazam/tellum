class CreateUserRatings < ActiveRecord::Migration
  def change
    create_table :user_ratings do |t|
      t.integer :rating_id
      t.integer :user_id
      t.timestamps
    end
  end
end
