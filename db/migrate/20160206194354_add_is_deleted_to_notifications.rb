class AddIsDeletedToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :is_deleted, :boolean, default: false
  end
end
