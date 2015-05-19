class Notification < ActiveRecord::Base
  attr_accessible :status, :object_name, :user_id, :tag_id, :rating_id, :reveal_id, :comment_id, :is_rejected, :is_accepted, :is_seen, :sender_id, :is_view
  has_many :comments
  has_many :tags
  belongs_to :user
  has_many :reveals
  belongs_to :rating

end
