json.response do
  if @user.present?
    if @notifications.present?
      json.status 'Ok'
      json.code 200
      json.message "Successfully Fetched relevant notifications..."
      json.notifications @notifications.each do |noti|
          sender_pic = User.find_by_id(noti.sender_id).try(:photo).try(:url)
          sender_user_name = User.find_by_id(noti.sender_id).try(:user_name)
          sender_full_name = User.find_by_id(noti.sender_id).try(:full_name)
          drop = noti.try(:rating)
          if noti.object_name == "Dropped"
            json.user_id noti.sender_id
            json.user_profile_picture sender_pic
            json.user_name sender_user_name
            json.user_full_name sender_full_name

            # json.drop_id noti.try(:rating_id)
            # json.drop_comment drop.try(:comment)
            # json.drop_ratings drop.try(:rating)
            # json.drop_creator_user_name drop.try(:user).try(:user_name)
            # json.drop_creator_name drop.try(:user).try(:full_name)
            # json.drop_created_at drop.try(:created_at)
            # json.drop_creator_user_id drop.try(:user_id)
            # json.drop_creator_profile_image drop.try(:user).try(:photo).try(:url)
            # json.drop_description drop.try(:comment)
            # json.drop_like_count drop.try(:rating_like_count)
            # json.drop_replies_count drop.try(:comments).try(:count)
            # json.is_anonymous_rating drop.try(:is_anonymous_rating)
            # json.is_like ( UserRating.where(user_id: @user.id, rating_id: drop.try(:id)).try(:last).try(:is_like) || false )

            json.box_id noti.try(:tag_id)
            json.box_title noti.try(:tag).try(:tag_line)
            json.class_id noti.try(:rating_id)
            json.class_secondary_id ""

            json.notification_id noti.id
            json.notification_created_at noti.try(:created_at)
            json.is_seen noti.is_seen
            json.object_name noti.object_name
          elsif noti.object_name ==  "Follow User"
            json.sender_user_id noti.sender_id
            json.sender_user_profile_picture sender_pic
            json.sender_user_name sender_user_name
            json.sender_user_full_name sender_full_name

            json.class_id ""
            json.class_secondary_id ""
            json.box_title ""
            json.user_id noti.user_id
            json.user_profile_picture noti.try(:user).try(:photo).try(:url)
            json.user_name noti.try(:user).try(:user_name)
            json.user_full_name noti.try(:user).try(:full_name)

            json.notification_id noti.id
            json.notification_created_at noti.try(:created_at)
            json.is_seen noti.is_seen
            json.object_name noti.object_name
          elsif noti.object_name == "comment"
            json.user_id noti.sender_id
            json.user_profile_picture sender_pic
            json.user_name sender_user_name
            json.user_full_name sender_full_name
            json.class_id noti.try(:rating_id)
            json.class_secondary_id ""
            json.box_id noti.try(:tag_id)
            json.box_title noti.try(:tag).try(:tag_line)


            json.notification_id noti.id
            json.notification_created_at noti.try(:created_at)
            json.is_seen noti.is_seen
            json.object_name noti.object_name

          elsif noti.object_name == "like rating"
            json.user_id noti.sender_id
            json.user_profile_picture sender_pic
            json.user_name sender_user_name
            json.user_full_name sender_full_name

            json.class_id noti.try(:rating_id)
            json.class_secondary_id ""
            json.box_id noti.try(:tag_id)
            json.box_title noti.try(:tag).try(:tag_line)

            json.notification_id noti.id
            json.notification_created_at noti.try(:created_at)
            json.is_seen noti.is_seen
            json.object_name noti.object_name
          else
            json.user_id noti.sender_id
            json.user_profile_picture sender_pic
            json.user_name sender_user_name
            json.user_full_name sender_full_name

            json.class_id noti.try(:rating_id)
            json.class_secondary_id noti.try(:reveal_id)
            json.box_id noti.try(:tag_id)
            json.box_title noti.try(:tag).try(:tag_line)

            json.reveal_id noti.try(:reveal_id)
            json.notification_id noti.id
            json.notification_created_at noti.try(:created_at)
            json.is_seen noti.is_seen
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
end