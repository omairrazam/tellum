class Notification < ActiveRecord::Base
  attr_accessible :status, :object_name, :user_id, :tag_id, :rating_id, :reveal_id, :comment_id, :is_rejected, :is_accepted, :is_seen, :sender_id, :is_view, :is_anonymous_user
  belongs_to :comment
  belongs_to :tag
  belongs_to :user
  belongs_to :reveal
  belongs_to :rating

end
