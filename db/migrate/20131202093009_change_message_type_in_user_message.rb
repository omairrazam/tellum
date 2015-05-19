class ChangeMessageTypeInUserMessage < ActiveRecord::Migration
  def up
    change_column :user_messages, :message, :text
  end

  def down
    change_column :user_messages, :message, :string
  end
end
