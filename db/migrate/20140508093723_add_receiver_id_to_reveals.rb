class AddReceiverIdToReveals < ActiveRecord::Migration
  def change
    add_column :reveals, :receiver_id, :integer
  end
end
