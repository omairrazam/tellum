json.response do
  unless @expiry_time == "expired"
    json.status true
    json.code 200
    json.message "Tag will expire after #{@expiry_time}"
    json.box @tag.attributes.merge!({remaining_time: @expiry_time})
  else
    json.status false
    json.code 401
    json.message "Your box has been expired"
  end
end
