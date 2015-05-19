class AddAudioFileUrlToRatings < ActiveRecord::Migration
  def change
    add_column :ratings, :audio_file_url, :string
  end
end
