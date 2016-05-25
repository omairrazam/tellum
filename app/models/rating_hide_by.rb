class RatingHideBy < ActiveRecord::Base
  belongs_to :rating
  belongs_to :user
  # attr_accessible :title, :body
end
