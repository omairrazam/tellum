if @tag.present?
  if @tag.try(:close_date).nil?
    json.status true
    json.tag_line @tag_line
  else
    json.status false
    json.tag_line @tag_line
  end
else
  json.status false
  json.tag_line @tag_line
end