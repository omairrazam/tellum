class UserFollow < ActiveRecord::Base
  attr_accessible :follow_id, :user_id, :is_accepted, :is_approved
  validates_presence_of :user_id
  belongs_to :user

  def is_follower(user)
    follower = UserFollow.where(follow_id: user.id, is_approved: true)
    unless following.nil?
      user[:is_follower] = true
    end
    user
  end
  def is_following(user)
    following = UserFollow.where(user_id: user.id, is_approved: true)
    unless following.nil?
      user[:is_following] = true
    end
    user
  end
  def user_following fb_users, auth_token
    user = User.where(authentication_token: auth_token)
    #sorted_users = Array.new
    followings_users = Array.new
    me_followings = UserFollow.where('follow_id = ? AND is_approved = ?',user.last.id, true )
    users = User.where('facebook_user_id IN (?) OR twitter_user_id in (?)', fb_users.collect{|user| user[:facebook_user_id]}, fb_users.collect{|user| user[:twitter_user_id]})
    #followings = UserFollow.where('follow_id in (?)', users.collect{|user| user.id}) if users.present?
    me_followings.collect{|user| followings_users << user.user } if me_followings.present?
    sorted_user = users - followings_users
    sorted_users = sorted_user - user
    sorted_users
  end

end
