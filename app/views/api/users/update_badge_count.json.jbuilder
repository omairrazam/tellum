json.response do
  if @user.present?
    json.status 'Ok'
    json.code 200
    json.message "Reset the badge count successfully"
    json.user @user
  else
    json.status 'Ok'
    json.code 201
    json.message "No user found"
  end
end
