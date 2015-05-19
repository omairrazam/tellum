class AddIsPasswordBlankToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_password_blank, :boolean, default: false
  end
end
