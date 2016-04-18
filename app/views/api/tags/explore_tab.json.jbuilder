#preparing the response
json.response do
  if @user.present?
    #assigning the status to Ok for http response
    json.status 'Ok'
    #setting the 200 http code
    json.code 200
    #adding the message variable in response
    json.message "Successfully Fetched relevant boxes..."
    #displaying the user the on which page he is
    json.current_page @page
    #returning the limit which is specified by the user to confirm that same limit is applied
    json.limit @limit
    #popuplating the actual data which is requested by the service
    json.boxes @user.explore_tab_boxes @offset, @limit
    #send the total available pages of the pagination
    json.total_pages (@user.explore_tab_boxes_count.to_f / @limit).ceil
    #json.drops @user.user_follow_drops + @user.user_created_drops
  else
    #if user is not present then sending the error response with status
    json.status 'not found'
    #sending 404 http status code
    json.code 404
    #adding the error message to let user know that what went wrong
    json.message "Ooooppps, user not found, please try later"
  end
end
