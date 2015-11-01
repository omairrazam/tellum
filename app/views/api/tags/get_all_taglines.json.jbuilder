json.response do
  if @tags.present?
    json.status 'ok'
    json.code 200
    json.message "Box Title fetched successfully..."
    json.boxes @tags.collect{|tag| tag.tag_line}
  else
    json.status 'Not found'
    json.code 404
    json.message "No tag found"
  end
end