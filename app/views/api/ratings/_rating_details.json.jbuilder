json.id @drop.id
json.rating @drop.rating
json.sub_rating @drop.sub_rating
json.comment @drop.comment
json.is_anonymous_rating @drop.is_anonymous_rating
json.is_post_to_wall @drop.is_post_to_wall
json.created_at @drop.created_at
json.updated_at @drop.updated_at
json.rating_like_count  @drop.rating_like_count
json.audio @drop.audio
json.audio_duration @drop.audio_duration
json.audio_file_url @drop.audio_file_url
json.reveal_id @drop.reveal_id
json.is_flagged @drop.is_flagged
json.ratings_comment_counts @drop.try(:comments).try(:count)
json.comments @drop.try(:comments)
json.is_like (UserRating.where(user_id: @user.try(:id), rating_id: @drop.id).try(:last).try(:is_like) || false)
