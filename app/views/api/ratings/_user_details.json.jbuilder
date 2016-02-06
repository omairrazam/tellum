json.id user.id
json.full_name user.try(:full_name)
json.gender user.try(:gender)
json.user_name user.try(:user_name)
json.device_token user.try(:device_token)
json.facebook_user_id user.try(:facebook_user_id)
json.email user.try(:email)
json.sign_in_count user.try(:sign_in_count)
json.authentication_token user.try(:authentication_token)
json.created_at user.try(:created_at)
json.updated_at user.try(:updated_at)
json.is_public_profile user.try(:is_public_profile)
json.is_following user.try(:is_following)
json.is_follower user.try(:is_follower)
json.is_email_confirmed user.try(:is_email_confirmed)
json.confirmation_token user.try(:confirmation_token)
json.confirmation_sent_at user.try(:confirmation_sent_at)
json.is_password_blank user.try(:is_password_blank)
json.badge_count user.try(:badge_count)
json.photo user.try(:photo).try(:url)
