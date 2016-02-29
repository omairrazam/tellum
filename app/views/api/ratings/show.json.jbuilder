json.response do
  if @drop.present?
    json.status 'Ok'
    json.code 200
    json.message "Successfully Fetched drop"
    json.rating do
      json.partial! 'rating_details', drop: @drop
      json.user do
        json.partial! 'user_details', user: @drop.try(:user)
      end
      json.tag_line do
        json.partial! 'tag_details', tag: @drop.try(:tag)
        json.user do
          json.partial! 'user_details', user: @drop.try(:tag).try(:user)
        end
      end

    end
  else
    json.status 'not found'
    json.code 404
    json.message "Ooooppps, drop not found, please try later"
  end
end