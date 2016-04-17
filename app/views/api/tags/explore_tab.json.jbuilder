json.response do
  if @user.present?
    json.status 'Ok'
    json.code 200
    json.message "Successfully Fetched relevant boxes..."
    json.current_page @page
    json.limit @limit
    json.boxes @user.explore_tab_boxes @offset, @limit
    json.total_pages (@user.explore_tab_boxes_count.to_f / @limit).ceil
    #json.drops @user.user_follow_drops + @user.user_created_drops
  else
    json.status 'not found'
    json.code 404
    json.message "Ooooppps, user not found, please try later"
  end
end
