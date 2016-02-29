class Reveal < ActiveRecord::Base
  attr_accessible :status, :rating_id, :user_id, :receiver_id
  belongs_to :user
  belongs_to :rating
  has_many :notifications
end
