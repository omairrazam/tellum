class AddDefaultValueToIsSeen < ActiveRecord::Migration
  def up
    change_column :notifications, :is_seen, :boolean, default: false
  end

  def down
    change_column :notifications, :is_seen, :boolean, default: false
  end
end
