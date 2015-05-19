class AddIsEmailConfirmedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_email_confirmed, :boolean, default: false
  end
end
