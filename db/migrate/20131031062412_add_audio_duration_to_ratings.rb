class AddAudioDurationToRatings < ActiveRecord::Migration
  def change
    add_column :ratings, :audio_duration, :string
  end
end
