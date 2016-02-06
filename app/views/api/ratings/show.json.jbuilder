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
        json.id @drop.try(:user_id)
        json.full_name @drop.try(:user).try(:full_name)
        json.gender @drop.try(:user).try(:gender)
        json.user_name @drop.try(:user).try(:user_name)
        json.device_token @drop.try(:user).try(:device_token)
        json.facebook_user_id @drop.try(:user).try(:facebook_user_id)
        json.email @drop.try(:user).try(:email)
        json.sign_in_count @drop.try(:user).try(:sign_in_count)
        json.authentication_token @drop.try(:user).try(:authentication_token)
        json.created_at @drop.try(:user).try(:created_at)
        json.updated_at @drop.try(:user).try(:updated_at)
        json.is_public_profile @drop.try(:user).try(:is_public_profile)
        json.is_following @drop.try(:user).try(:is_following)
        json.is_follower @drop.try(:user).try(:is_follower)
        json.is_email_confirmed @drop.try(:user).try(:is_email_confirmed)
        json.confirmation_token @drop.try(:user).try(:confirmation_token)
        json.confirmation_sent_at @drop.try(:user).try(:confirmation_sent_at)
        json.is_password_blank @drop.try(:user).try(:is_password_blank)
        json.badge_count @drop.try(:user).try(:badge_count)
        json.photo @drop.try(:user).try(:photo).try(:url)
      end

    end
  else
    json.status 'not found'
    json.code 404
    json.message "Ooooppps, drop not found, please try later"
  end
end