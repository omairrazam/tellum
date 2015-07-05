json.response do
  if @total_drops.present?
    json.status 'ok'
    json.code 200
    json.message "Successfully got total drops."
    json.box_description @total_drops
  else
    json.status 'not found'
    json.code 404
    json.message "Ooooppps, There is no drop associated with the requested box."
  end
end