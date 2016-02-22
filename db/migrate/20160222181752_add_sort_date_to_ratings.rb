class AddSortDateToRatings < ActiveRecord::Migration
  def change
    add_column :ratings, :sort_date, :datetime
  end
end
