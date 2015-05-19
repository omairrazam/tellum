json.response do
  if @users.present?
    json.status 'Ok'
    json.code 200
    json.message "User Following Lists"
    json.user @users
  else
    json.status 'Ok'
    json.code 201
    json.message "No user found"
  end
end
