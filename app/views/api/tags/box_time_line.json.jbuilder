json.response do
  if @user.present?
    json.status 'Ok'
    json.code 200
    json.message "Successfully Fetched relevant boxes..."
    json.boxes (@user.user_created_and_following_boxes.reject(&:blank?) + @user.user_created_and_following_drops.reject(&:blank?)).sort!{ |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }
    #json.drops @user.user_follow_drops + @user.user_created_drops
  else
    json.status 'not found'
    json.code 404
    json.message "Ooooppps, user not found, please try later"
  end
end
