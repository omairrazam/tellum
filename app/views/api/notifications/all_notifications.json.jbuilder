if @user.present?
  if @notifications.present?
    json.status 'Ok'
    json.code 200
    json.message "Successfully Fetched relevant notifications..."
    json.notifications @notifications.each do |noti|
        if noti.tag_id.present? && noti.rating_id.present?
          json.user_id noti.user_id
          json.user_profile_picture noti.try(:user).try(:photo).try(:url)
          json.user_name noti.try(:user).try(:user_name)
          json.user_full_name noti.try(:user).try(:full_name)
          json.box_id noti.try(:tag_id)
          json.box_title noti.try(:tag).try(:tag_line)
          json.drop_id noti.try(:rating_id)
          json.drop_comment noti.try(:rating).try(:comment)
          json.drop_ratings noti.try(:rating).try(:rating)
          json.notification_id noti.id
          json.notification_created_at noti.try(:created_at)
          json.object_name noti.object_name
        else
          json.user_id noti.user_id
          json.user_profile_picture noti.try(:user).try(:photo).try(:url)
          json.user_name noti.try(:user).try(:user_name)
          json.user_full_name noti.try(:user).try(:full_name)
          # json.box_id noti.try(:tag_id)
          # json.box_title noti.try(:tag).try(:tag_line)
          json.drop_id noti.try(:rating_id)
          json.drop_comment noti.try(:rating).try(:comment)
          json.drop_ratings noti.try(:rating).try(:rating)
          json.notification_id noti.id
          json.notification_created_at noti.try(:created_at)
          json.object_name noti.object_name
        end
    end
  else
    json.status 'not found'
    json.code 404
    json.message "Ooooppps, notifications not found, please try later"
  end
else
  json.status 'not found'
  json.code 404
  json.message "Ooooppps, user not found, please try later"
end