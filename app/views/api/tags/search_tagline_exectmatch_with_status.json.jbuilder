if @tag.present?
  if @tag.close_date.nil?
    json.status "ok"
    json.tag_line @tag_line
  else
    json.status "no"
    json.tag_line @tag_line
  end
else
  json.status "ok"
  json.tag_line @tag_line
end