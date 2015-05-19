class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.integer :code
      t.string :status
      t.string :detail
      t.string :custom_message
      t.timestamps
    end
  end
end
