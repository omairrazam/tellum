class FollowUser < ActiveRecord::Base
  attr_accessible :tag_id, :user_id
  has_many :users, :dependent => :destroy
  has_many :tags, :dependent => :destroy
end
