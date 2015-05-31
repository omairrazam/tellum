class AddExpiryTimeToTags < ActiveRecord::Migration
  def change
    add_column :tags, :expiry_time, :float
  end
end
