if @user.present?
  json.status 'ok'
  json.code 200
  json.message "Successfully got total drops."
  json.user_created_boxes @user.user_created_box
  json.user_following_boxes @user.user_follow_boxes
  json.user_not_following_boxes @user.user_not_follow_boxes
else
  json.status 'not found'
  json.code 404
  json.message "Ooooppps, user not found, please try later"
end