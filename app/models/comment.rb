class Comment < ActiveRecord::Base
  attr_accessible :comment, :rating_id, :user_id, :is_anonymous_comment
  belongs_to :user
  belongs_to :rating
  has_many :notifications
end
