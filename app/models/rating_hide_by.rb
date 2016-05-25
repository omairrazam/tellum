class RatingHideBy < ActiveRecord::Base
  belongs_to :rating
  belongs_to :user
  attr_accessible :rating_id, :user_id

  validates_presence_of :rating_id
  validates_presence_of :user_id
end
