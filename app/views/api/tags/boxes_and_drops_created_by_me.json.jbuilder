json.response do
  if @user.present?
    json.status 'Ok'
    json.code 200
    json.message "Successfully Fetched relevant boxes..."
    json.boxes (@user.box_story_hash_structure(@boxes) + @user.drop_story_hash_structure(@drops)).sort!{ |a ,b| b["sort_created_at"] <=> a["sort_created_at"] }
    #json.drops @user.user_follow_drops + @user.user_created_drops
  else
    json.status 'not found'
    json.code 404
    json.message "Ooooppps, user not found, please try later"
  end
end
