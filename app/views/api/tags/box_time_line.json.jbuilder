if @user.present?
  json.status 'ok'
  json.code 200
  json.message "Successfully got total drops."
  json.boxes @user.user_created_box + @user.user_follow_boxes + @user.user_not_follow_boxes
else
  json.status 'not found'
  json.code 404
  json.message "Ooooppps, user not found, please try later"
end