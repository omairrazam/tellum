class ChangeDataTypeForRating < ActiveRecord::Migration
  def self.up
    change_table :ratings do |t|
      t.change :rating, :integer
    end
  end
  def self.down
    change_table :ratings do |t|
      t.change :rating, :integer
    end
  end
end
