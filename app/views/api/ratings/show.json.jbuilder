json.response do
  if @drop.present?
    json.status 'Ok'
    json.code 200
    json.message "Successfully Fetched drop"
    json.drop do
      json.id @drop.id
      json.rating @drop.rating
      #json.box_id @drop.tag_id
      json.sub_rating @drop.sub_rating
      json.comment @drop.comment
      json.is_anonymous_rating @drop.is_anonymous_rating
      json.is_post_to_wall @drop.is_post_to_wall
      json.created_at @drop.created_at
      json.updated_at @drop.updated_at
      json.rating_like_count  @drop.rating_like_count
      #json.user_id @drop.user_id
      json.audio @drop.audio
      json.audio_duration @drop.audio_duration
      json.audio_file_url @drop.audio_file_url
      json.reveal_id @drop.reveal_id
      json.is_flagged @drop.is_flagged
      json.ratings_comment_counts @drop.try(:comments).try(:count)
      json.comments @drop.try(:comments)
      json.is_like (UserRating.where(user_id: @user.try(:id), rating_id: @drop.id).try(:last).try(:is_like) || false)
      json.user do
        json.partial! 'user_details', user: @drop.try(:user)
      end
      json.tag_line do
        json.id @drop.try(:tag_id)
        json.tag_line @drop.try(:tag).try(:tag_line)
        json.tag_title @drop.try(:tag).try(:tag_title)
        json.tag_description @drop.try(:tag).try(:tag_description)
        json.open_date @drop.try(:tag).try(:open_date)
        json.close_date @drop.try(:tag).try(:close_date)
        json.is_private @drop.try(:tag).try(:is_private)
        json.is_allow_anonymous @drop.try(:tag).try(:is_allow_anonymous)
        json.is_post_to_wall @drop.try(:tag).try(:is_post_to_wall)
        json.created_at @drop.try(:tag).try(:created_at)
        json.updated_at @drop.try(:tag).try(:updated_at)
        json.is_locked @drop.try(:tag).try(:is_locked)
        json.updated_time @drop.try(:tag).try(:updated_time)
        json.is_flagged @drop.try(:tag).try(:is_flagged)
        json.expiry_time @drop.try(:tag).try(:expiry_time)
        json.average_rating @drop.try(:tag).try(:average_rating)
        json.total_rating @drop.try(:tag).try(:total_rating)

        json.user do
          json.partial! 'user_details', user: @drop.try(:user)
        end
      end

    end
  else
    json.status 'not found'
    json.code 404
    json.message "Ooooppps, drop not found, please try later"
  end
end