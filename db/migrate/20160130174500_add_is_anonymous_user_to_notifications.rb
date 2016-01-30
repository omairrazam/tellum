class AddIsAnonymousUserToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :is_anonymous_user, :boolean, default: false
  end
end
