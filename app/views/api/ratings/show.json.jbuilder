json.response do
  if @drop.present?
    json.status 'Ok'
    json.code 200
    json.message "Successfully Fetched drop"
    json.drop do
      json.drop_id @drop.id
      json.drop_rating @drop.rating
      json.box_id @drop.tag_id
      json.drop_sub_rating @drop.sub_rating
      json.drop_comment @drop.comment
      json.is_anonymous_rating @drop.is_anonymous_rating
      json.is_post_to_wall @drop.is_post_to_wall
      json.drop_created_at (@drop.created_at - 8.minutes)
      json.drop_updated_at @drop.updated_at
      json.rating_like_count  @drop.rating_like_count
      json.user_id @drop.user_id
      json.drop_audio @drop.audio
      json.audio_duration @drop.audio_duration
      json.audio_file_url @drop.audio_file_url
      json.reveal_id @drop.reveal_id
      json.is_flagged @drop.is_flagged
    end
  else
    json.status 'not found'
    json.code 404
    json.message "Ooooppps, drop not found, please try later"
  end
end
