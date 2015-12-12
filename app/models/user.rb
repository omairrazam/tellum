class User < ActiveRecord::Base
  mount_uploader :photo, PhotoUploader
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable , :token_authenticatable, :confirmable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :full_name, :user_name, :skip_password_form,
                  :photo, :gender, :phone, :location, :device_token, :about_me, :twitter_user_id, :facebook_user_id,
                  :is_following, :is_follower, :is_public_profile, :reveal_id, :is_email_confirmed, :is_password_blank, :badge_count

  extend Tellum::HideProtectedFields
  protected_fields [:encrypted_password, :reset_password_token, :reset_password_sent_at, :remember_created_at, :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip  ] do |pf|
    pf.keep_if{ |k, v| !v.nil? }.keep_if { |k, v| k != "photo" }.merge!((User.find(pf["id"]).photo.url.present? rescue false) ? { "photo" =>  { "url" => User.find(pf["id"]).photo.url } } : {} )
  end
  attr_accessor :skip_password_form
  has_many :user_ratings
  has_many :tags
  has_many :flagged_boxes, foreign_key: :user_id
  has_many :flagged_drops, foreign_key: :user_id
  has_many :received_messages, :class_name=>"UserMessage" , :foreign_key => "receiver_id"
  has_many :sent_messages, :class_name=>"UserMessage" , :foreign_key => "sender_id"
  has_many :ratings
  has_many :comments
  belongs_to :user_follow
  belongs_to :comment
  has_many :reveal
  has_many :notifications
  has_many :user_follows
  validates :full_name, :presence => true
  validates :email, uniqueness: { :case_sensitive => false }, :allow_blank => true, :if => :email_changed?
  validates :user_name, :presence => true, uniqueness: { :case_sensitive => false }, format: { with: /^[^ ]+$/ }
  #validates_uniqueness_of :user_name
  validates_uniqueness_of :facebook_user_id, if: Proc.new { |u| u.facebook_user_id.present? }
  validates_uniqueness_of :twitter_user_id, if: Proc.new { |u| u.twitter_user_id.present? }
  validates :gender, :presence => true, if: Proc.new { |u| u.skip_password_form.blank?  }
  validates :device_token, :presence => true
  before_save :ensure_authentication_token
  before_save { |user|  user.is_email_confirmed = true  if user.confirmed_at_changed? && !user.new_record? }

  def self.authenticate(username, password)
    user = User.find_for_authentication(:user_name => username)
    user.try(:valid_password?, password) ? user : nil
  end

  def photo=(p)
    tmp_file = Tempfile.new "file_upload_#{SecureRandom.hex(3)}.jpg"
    tmp_file.binmode
    tmp_file.write(Base64.decode64(p))
    super(ActionDispatch::Http::UploadedFile.new(tempfile: tmp_file, filename: "user_avatar_#{SecureRandom.hex(5)}.jpg" ))
  end
  def user_created_box
    self.try(:tags).collect{|tag| {box_id: tag.id,box_creator_name: tag.try(:user).try(:full_name), box_name: tag.tag_line, box_created_at: tag.created_at.strftime("%d-%m-%Y %H:%M:%S"), box_title: tag.tag_title, is_allow_anonymous: tag.try(:is_allow_anonymous), is_flagged: tag.try(:is_flagged),is_locked: tag.try(:is_locked), is_post_to_wall: tag.try(:is_post_to_wall), is_private: tag.try(:is_private), open_date: tag.try(:open_date), close_date: tag.try(:close_date), box_description: tag.tag_description, box_creator_id: tag.user_id, box_creator_image: tag.try(:user).try(:photo).try(:url), box_creator_user_name: tag.try(:user).try(:full_name), box_creator_user_name: tag.try(:user).try(:user_name), is_follower: check_user(tag.try(:user), self),box_expiry: tag.expiry_time, box_total_drops: tag.try(:ratings).try(:count)}.merge({drops: tag.try(:ratings).limit(3).collect{|drop| {drop_id: drop.id, drop_creator_user_name: drop.try(:user).try(:user_name), drop_creator_name: drop.try(:user).try(:full_name), drop_created_at: drop.try(:created_at).strftime("%d-%m-%Y %H:%M:%S"), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.user.try(:photo).try(:url), drop_description: drop.comment, is_anonymous_rating: drop.is_anonymous_rating, drop_like_count: drop.rating_like_count, drop_replies_count: drop.comments.count, is_like: ( UserRating.where(user_id: self.id, rating_id: drop.id).try(:last).try(:is_like) || false )}}})}
  end
  def user_follow_boxes
    users = UserFollow.where(follow_id: self.id)
    collect_data users
    #UserFollow.where(follow_id: self.id).collect{|user| user.try(:user).try(:tags).where(is_private: false).collect{|tag| {box_name: tag.tag_line, box_title: tag.tag_title, box_description: tag.tag_description, box_creator_id: tag.user_id, box_creator_image: tag.try(:user).try(:photo).try(:url), box_creator_user_name: tag.try(:user).try(:full_name), box_creator_user_name: tag.try(:user).try(:user_name), box_expiry: tag.expiry_time, box_total_drops: tag.try(:ratings).try(:count)}.merge({drops: tag.try(:ratings).limit(3).collect{|drop| {drop_creator_user_id: drop.try(:user).try(:user_name), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.user.try(:photo).try(:url), drop_description: drop.comment, drop_like_count: drop.rating_like_count, drop_replies_count: drop.comments.count}}})}}
  end
  def user_not_follow_boxes
    users=UserFollow.where("follow_id != ?", self.id)
    collect_data users
    #users.collect{|user| user.try(:user).try(:tags).where(is_private: false).collect{|tag| {box_name: tag.tag_line, box_title: tag.tag_title, box_description: tag.tag_description, box_creator_id: tag.user_id, box_creator_image: tag.try(:user).try(:photo).try(:url), box_creator_user_name: tag.try(:user).try(:full_name), box_creator_user_name: tag.try(:user).try(:user_name), box_expiry: tag.expiry_time, box_total_drops: tag.try(:ratings).try(:count)}.merge({drops: tag.try(:ratings).limit(3).collect{|drop| {drop_creator_user_id: drop.try(:user).try(:user_name), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.user.try(:photo).try(:url), drop_description: drop.comment, drop_like_count: drop.rating_like_count, drop_replies_count: drop.comments.count}}})}}
  end
  def collect_data users
    array = Array.new
    if users.present?
      users.each do |user|
        user.try(:user).try(:tags).where(is_private: false).each do |tag|
          array << { box_id: tag.id, box_name: tag.tag_line, box_description: tag.tag_description, is_allow_anonymous: tag.try(:is_allow_anonymous), is_flagged: tag.try(:is_flagged),is_locked: tag.try(:is_locked), is_post_to_wall: tag.try(:is_post_to_wall), is_private: tag.try(:is_private), open_date: tag.try(:open_date), close_date: tag.try(:close_date), box_creator_id: tag.user_id, box_creator_image: tag.try(:user).try(:photo).try(:url), box_creator_name: tag.try(:user).try(:full_name), box_creator_user_name: tag.try(:user).try(:user_name), is_follower: check_user(tag.try(:user), self), box_created_at: tag.created_at.strftime("%d-%m-%Y %H:%M:%S"), box_expiry: tag.expiry_time, box_total_drops: tag.try(:ratings).try(:count)}.merge({drops: tag.try(:ratings).limit(3).collect{|drop| {drop_id: drop.id, drop_creator_user_name: drop.try(:user).try(:user_name), drop_creator_name: drop.try(:user).try(:full_name), drop_created_at: drop.try(:created_at).strftime("%d-%m-%Y %H:%M:%S"), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.user.try(:photo).try(:url), drop_description: drop.comment, drop_like_count: drop.rating_like_count, drop_replies_count: drop.comments.count, is_anonymous_rating: drop.is_anonymous_rating, is_like: ( UserRating.where(user_id: self.id, rating_id: drop.id).try(:last).try(:is_like) || false ) }}})
        end
      end
    end
    array
  end
  def email_required?
    super && skip_password_form.blank?
  end
  def password_required?
    super && skip_password_form.blank?
  end
  def self.find_by_facebook_id(id)
    find_by_facebook_user_id(id)
  end
  def self.find_with_email(email)
    find_by_email(email)
  end
  def email_required?
    false
  end

  def email_changed?
    true
  end
  def resend_generate_confirmation_token
    self.generate_confirmation_token!
  end
  def check_facebook_users params, user_following
    user_list = User.where('facebook_user_id is not NULL')
  end
  def check_user(user, current_user)
    following = UserFollow.where(follow_id: current_user.id, user_id: user.id, is_approved: true)
    puts "user #{user.attributes} and currnet_user #{self.attributes}"
    if following.present?
      true
    else
      false
    end

  end
end
