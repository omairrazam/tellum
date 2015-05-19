class AddPasswordBlankToUser < ActiveRecord::Migration
  def change
    add_column :users, :blank_password, :boolean
  end
end
