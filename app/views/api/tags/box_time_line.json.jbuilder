json.response do
  if @user.present?
    json.status 'Ok'
    json.code 200
    json.message "Successfully Fetched relevant boxes..."
    json.boxes @user.user_created_box + @user.user_created_box_and_drops + @user.user_follow_boxes + @user.user_follow_boxes_and_drops+ @user.user_follow_drops + @user.user_created_drops
    #json.drops @user.user_follow_drops + @user.user_created_drops
  else
    json.status 'not found'
    json.code 404
    json.message "Ooooppps, user not found, please try later"
  end
end
