class AddMergedAccountToUser < ActiveRecord::Migration
  def change
    add_column :users, :merged_account, :boolean
  end
end
