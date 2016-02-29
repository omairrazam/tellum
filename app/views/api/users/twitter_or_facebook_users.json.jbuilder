json.response do
  if @user.present?
    if @users.present?
      json.status 'Ok'
      json.code 200
      json.message 'Users Matched Successfully.'
      json.users do
        json.array! @users do |user|
          json.id user.try(:id)
          json.about_me user.try(:about_me)
          json.badge_count user.try(:badge_count)
          json.blank_password user.try(:blank_password)
          json.created_at user.try(:created_at)
          json.updated_at user.try(:updated_at)
          json.device_token user.try(:device_token)
          json.email user.try(:email)
          json.facebook_user_id user.try(:facebook_user_id)
          json.twitter_user_id user.try(:twitter_user_id)
          json.user_name user.try(:user_name)
          json.full_name user.try(:full_name)
          json.gender user.try(:gender)
          json.is_email_confirmed user.try(:is_email_confirmed)
          json.is_follower user.check_user_follower(user, @user)
          json.is_following user.check_user_following(user, @user)
          json.is_password_blank user.try(:is_password_blank)
          json.is_public_profile user.try(:is_public_profile)
          json.location user.try(:location)
          json.merged_account user.try(:merged_account)
          json.phone user.try(:phone)
          json.photo user.try(:photo)
          json.reveal_id user.try(:reveal_id)
        end
      end
    else
      json.status 'not found'
      json.code 404
      json.message "No User Matched "
    end
  else
    json.status 'auth token invalid'
    json.code 501
    json.message "Please login to continue ..."
  end
end