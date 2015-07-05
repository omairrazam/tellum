json.response do
  if @box_detail.present?
    json.status 'ok'
    json.code 200
    json.message "Box Detail Successfully Fetched"
    json.box_description @box_detail.try(:tag_description)
  else
    json.status 'not found'
    json.code 404
    json.message "Box ID doesn't match the existing Box ID's Please try with other ID"
  end
end