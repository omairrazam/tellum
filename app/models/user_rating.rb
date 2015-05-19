class UserRating < ActiveRecord::Base
  attr_accessible :rating_id, :user_id, :is_like
  #validates_uniqueness_of :rating_id
  belongs_to :rating
  belongs_to :user

  def is_like
    l = read_attribute(:is_like)
    return false if l.nil?
    l
  end
end
