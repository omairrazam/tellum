class CreateReveals < ActiveRecord::Migration
  def change
    create_table :reveals do |t|
      t.boolean :status
      t.references :user
      t.references :rating
      t.timestamps
    end
  end
end
