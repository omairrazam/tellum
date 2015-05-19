class AddAudioToRatings < ActiveRecord::Migration
  def change
    add_column :ratings, :audio, :string
  end
end
