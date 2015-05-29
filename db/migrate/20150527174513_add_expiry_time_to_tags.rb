class AddExpiryTimeToTags < ActiveRecord::Migration
  def change
    add_column :tags, :expiry_time, :datetime
  end
end
