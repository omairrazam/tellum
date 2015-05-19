class CreateTests < ActiveRecord::Migration
  def change
    create_table :tests do |t|
      t.string :first_name
      t.string :last_name_string
      t.integer :age

      t.timestamps
    end
  end
end
