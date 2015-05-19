class CreateUserUnfollows < ActiveRecord::Migration
  def change
    create_table :user_unfollows do |t|
      t.integer :user_id
      t.integer :unfollow_id

      t.timestamps
    end
  end
end
