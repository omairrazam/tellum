class AddIsViewToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :is_view, :boolean
  end
end
