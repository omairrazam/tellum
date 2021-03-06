class User < ActiveRecord::Base
  mount_uploader :photo, PhotoUploader
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :token_authenticatable, :confirmable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :full_name, :user_name, :skip_password_form,
                  :photo, :gender, :phone, :location, :device_token, :about_me, :twitter_user_id, :facebook_user_id,
                  :is_following, :is_follower, :is_public_profile, :reveal_id, :is_email_confirmed, :is_password_blank, :badge_count

  extend Tellum::HideProtectedFields
  protected_fields [:encrypted_password, :reset_password_token, :reset_password_sent_at, :remember_created_at, :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip] do |pf|
    pf.keep_if { |k, v| !v.nil? }.keep_if { |k, v| k != "photo" }.merge!((User.find(pf["id"]).photo.url.present? rescue false) ? {"photo" => {"url" => User.find(pf["id"]).photo.url}} : {})
  end
  attr_accessor :skip_password_form

  has_many :user_ratings
  has_many :tags
  has_many :flagged_boxes, foreign_key: :user_id
  has_many :flagged_drops, foreign_key: :user_id
  has_many :received_messages, :class_name => "UserMessage", :foreign_key => "receiver_id"
  has_many :sent_messages, :class_name => "UserMessage", :foreign_key => "sender_id"
  has_many :ratings
  has_many :comments
  belongs_to :user_follow
  belongs_to :comment
  has_many :reveal
  has_many :notifications
  has_many :user_follows
  validates :full_name, :presence => true
  validates :email, uniqueness: {:case_sensitive => false}, :allow_blank => true, :if => :email_changed?
  validates :user_name, :presence => true, uniqueness: {:case_sensitive => false}, format: {with: /^[^ ]+$/}
  #validates_uniqueness_of :user_name
  validates_uniqueness_of :facebook_user_id, if: Proc.new { |u| u.facebook_user_id.present? }
  validates_uniqueness_of :twitter_user_id, if: Proc.new { |u| u.twitter_user_id.present? }

  #modified by aesquares
  # commenting this validation check according to the requirement of this ticket TELL-BUG-2016-2 (Sign up - Gender)
  # url to the ticket is: https://trello.com/c/D8TRhBea/4-tell-bug-2016-2-sign-up-gender
  # validates :gender, :presence => true, if: Proc.new { |u| u.skip_password_form.blank? }
  validates :gender, :inclusion => {:in => %w{male female}, :case_sensitive => false, :message => 'gender can be either male or female in lowercase'}, if: Proc.new { |u| u.gender.present? }
  validates :device_token, :presence => true
  before_save :ensure_authentication_token
  before_save { |user| user.is_email_confirmed = true if user.confirmed_at_changed? && !user.new_record? }

  def self.authenticate(username, password)
    user = User.find_for_authentication(:user_name => username)
    user.try(:valid_password?, password) ? user : nil
  end

  def photo=(p)
    tmp_file = Tempfile.new "file_upload_#{SecureRandom.hex(3)}.jpg"
    tmp_file.binmode
    tmp_file.write(Base64.decode64(p))
    super(ActionDispatch::Http::UploadedFile.new(tempfile: tmp_file, filename: "user_avatar_#{SecureRandom.hex(5)}.jpg"))
  end

  def user_created_box_and_drops
    self.try(:tags).collect do |tag|
      if tag.try(:ratings).where("user_id != ? AND user_id NOT IN(?)", self.try(:id), following_users).count > 0
        {box_id: tag.try(:id), is_drop_story: false, box_creator_name: tag.try(:user).try(:full_name), box_name: tag.try(:tag_line), box_created_at: tag.try(:created_at), sort_created_at: tag.try(:created_at), box_title: tag.try(:tag_title), is_allow_anonymous: tag.try(:is_allow_anonymous), is_flagged: tag.try(:is_flagged), is_locked: tag.try(:is_locked), is_post_to_wall: tag.try(:is_post_to_wall), is_private: tag.try(:is_private), open_date: tag.try(:open_date), close_date: tag.try(:close_date), box_description: tag.try(:tag_description), box_creator_id: tag.try(:user_id), box_creator_image: tag.try(:user).try(:photo).try(:url), box_creator_user_name: tag.try(:user).try(:full_name), box_creator_user_name: tag.try(:user).try(:user_name), is_follower: check_user(tag.try(:user), self), box_expiry: tag.try(:expiry_time), box_total_drops: tag.try(:ratings).try(:count)}.merge({drops: tag.try(:ratings).where("user_id != ? AND user_id NOT IN(?)", self.try(:id), following_users).limit(3).collect { |drop| {drop_id: drop.try(:id), drop_creator_user_name: drop.try(:user).try(:user_name), drop_creator_name: drop.try(:user).try(:full_name), drop_created_at: drop.try(:created_at), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.try(:user).try(:photo).try(:url), drop_description: drop.try(:comment), is_anonymous_rating: drop.try(:is_anonymous_rating), drop_like_count: drop.try(:rating_like_count), drop_replies_count: drop.try(:comments).try(:count), is_like: (UserRating.where(user_id: self.id, rating_id: drop.try(:id)).try(:last).try(:is_like) || false)} }})
      end
    end
  end

  def user_created_box
    self.try(:tags).collect { |tag| {box_id: tag.try(:id), is_drop_story: false, box_creator_name: tag.try(:user).try(:full_name), box_name: tag.try(:tag_line), box_created_at: tag.try(:created_at), sort_created_at: tag.try(:created_at), box_title: tag.try(:tag_title), is_allow_anonymous: tag.try(:is_allow_anonymous), is_flagged: tag.try(:is_flagged), is_locked: tag.try(:is_locked), is_post_to_wall: tag.try(:is_post_to_wall), is_private: tag.try(:is_private), open_date: tag.try(:open_date), close_date: tag.try(:close_date), box_description: tag.try(:tag_description), box_creator_id: tag.try(:user_id), box_creator_image: tag.try(:user).try(:photo).try(:url), box_creator_user_name: tag.try(:user).try(:full_name), box_creator_user_name: tag.try(:user).try(:user_name), is_follower: check_user(tag.try(:user), self), box_expiry: tag.try(:expiry_time), box_total_drops: tag.try(:ratings).try(:count), drops: []} }
  end


  def user_hidden_drops
    RatingHideBy.where(:user_id => self.id).collect { |r| r.rating_id }
  end


  def user_created_and_following_drops
    hiddenDrops = self.user_hidden_drops
    drops = Rating.where("user_id = ?", self.id)
    drops = drops.where("id NOT IN (?) ", hiddenDrops) if hiddenDrops.length > 0
    (drops + following_drops_with_is_anonymous_false).collect { |drop|
      {box_id: drop.try(:tag).try(:id), is_drop_story: true, box_name: drop.try(:tag).try(:tag_line), sort_created_at: drop.try(:sort_date),
       box_description: drop.try(:tag).try(:tag_description), is_allow_anonymous: drop.try(:tag).try(:is_allow_anonymous), is_flagged: drop.try(:tag).try(:is_flagged),
       is_locked: drop.try(:tag).try(:is_locked), is_post_to_wall: drop.try(:tag).try(:is_post_to_wall), is_private: drop.try(:tag).try(:is_private), open_date: drop.try(:tag).try(:open_date),
       close_date: drop.try(:tag).try(:close_date), box_creator_id: drop.try(:tag).try(:user_id), box_creator_image: drop.try(:tag).try(:user).try(:photo).try(:url),
       box_creator_name: drop.try(:tag).try(:user).try(:full_name), box_creator_user_name: drop.try(:tag).try(:user).try(:user_name), is_follower: check_user(drop.try(:tag).try(:user), self),
       box_created_at: drop.try(:tag).try(:created_at), box_expiry: drop.try(:tag).try(:expiry_time), box_total_drops: drop.try(:tag).try(:ratings).try(:count)}.merge({drops: [{drop_id: drop.try(:id), drop_creator_user_name: drop.try(:user).try(:user_name), drop_creator_name: drop.try(:user).try(:full_name), drop_created_at: drop.try(:created_at), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.try(:user).try(:photo).try(:url), drop_description: drop.try(:comment), drop_like_count: drop.try(:rating_like_count), drop_replies_count: drop.try(:comments).try(:count), sort_created_at: drop.try(:created_at), is_anonymous_rating: drop.try(:is_anonymous_rating), is_like: (UserRating.where(user_id: self.id, rating_id: drop.try(:id)).try(:last).try(:is_like) || false), drop_hidden_by_users: drop.drop_hidden_by_users}]})
    }
    
  end

  def following_drops_with_is_anonymous_false
    Rating.where("user_id IN (?) AND is_box_locked is false AND is_anonymous_rating = ? AND id not in (?)", following_users, false, self.user_hidden_drops)
  end

  def drop_story_hash_structure drops, exclude_hidden_drops = false
    if exclude_hidden_drops and self.user_hidden_drops.present?
      drops = drops.where('id NOT in(?)', self.user_hidden_drops)
    end
    drops.collect { |drop|
      {box_id: drop.try(:tag).try(:id), is_drop_story: true, box_name: drop.try(:tag).try(:tag_line), sort_created_at: drop.try(:sort_date),
       box_description: drop.try(:tag).try(:tag_description), is_allow_anonymous: drop.try(:tag).try(:is_allow_anonymous), is_flagged: drop.try(:tag).try(:is_flagged),
       is_locked: drop.try(:tag).try(:is_locked), is_post_to_wall: drop.try(:tag).try(:is_post_to_wall), is_private: drop.try(:tag).try(:is_private), open_date: drop.try(:tag).try(:open_date),
       close_date: drop.try(:tag).try(:close_date), box_creator_id: drop.try(:tag).try(:user_id), box_creator_image: drop.try(:tag).try(:user).try(:photo).try(:url),
       box_creator_name: drop.try(:tag).try(:user).try(:full_name), box_creator_user_name: drop.try(:tag).try(:user).try(:user_name), is_follower: check_user(drop.try(:tag).try(:user), self),
       box_created_at: drop.try(:tag).try(:created_at), box_expiry: drop.try(:tag).try(:expiry_time), box_total_drops: drop.try(:tag).try(:ratings).try(:count)}.merge({drops: [{drop_id: drop.try(:id), drop_creator_user_name: drop.try(:user).try(:user_name), drop_creator_name: drop.try(:user).try(:full_name), drop_created_at: drop.try(:created_at), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.try(:user).try(:photo).try(:url), drop_description: drop.try(:comment), drop_like_count: drop.try(:rating_like_count), drop_replies_count: drop.try(:comments).try(:count), sort_created_at: drop.try(:created_at), is_anonymous_rating: drop.try(:is_anonymous_rating), is_like: (UserRating.where(user_id: self.id, rating_id: drop.try(:id)).try(:last).try(:is_like) || false), drop_hidden_by_users: drop.drop_hidden_by_users}]})
    }
  end

  def following_users
    UserFollow.where(follow_id: self.id).collect { |u| u.user_id }
  end

  def user_follow_boxes
    users = UserFollow.where(follow_id: self.id).collect { |u| u.user_id }
    collect_data users
  end

  def user_follow_boxes_and_drops
    users = UserFollow.where(follow_id: self.id).collect { |u| u.user_id }
    collect_drops_data users
  end

  def get_tag_ids_to_hide hiddenDrops
    Rating.where(id: hiddenDrops).collect { |drop| drop.try(:tag_id) }
  end

  # updated by Kamran Hameed (Aesquares)
  # now we are going to add drop_hidden_by_users because we need to hide the drop for those users who had hide the from their account
  def user_created_and_following_boxes
    hiddenDrops = self.user_hidden_drops
    notIn = get_tag_ids_to_hide hiddenDrops
    @tags = Tag.where('(user_id = ? OR user_id IN (?)) AND close_date is not NULL AND open_date is not NULL', self.id, following_users)
    @tags = @tags.where('id not in (?)',notIn) if notIn.length > 0 

    @tags.map do |tag|
      {box_id: tag.try(:id), is_drop_story: false, box_creator_name: tag.try(:user).try(:full_name), box_name: tag.try(:tag_line), box_created_at: tag.try(:created_at), sort_created_at: tag.try(:created_at), box_title: tag.try(:tag_title), is_allow_anonymous: tag.try(:is_allow_anonymous), is_flagged: tag.try(:is_flagged), is_locked: tag.try(:is_locked), is_post_to_wall: tag.try(:is_post_to_wall), is_private: tag.try(:is_private), open_date: tag.try(:open_date), close_date: tag.try(:close_date), box_description: tag.try(:tag_description), box_creator_id: tag.try(:user_id), box_creator_image: tag.try(:user).try(:photo).try(:url), box_creator_user_name: tag.try(:user).try(:full_name), box_creator_user_name: tag.try(:user).try(:user_name), is_follower: check_user(tag.try(:user), self), box_expiry: tag.try(:expiry_time), box_total_drops: tag.try(:ratings).try(:count)}.merge({drops_count: tag.ratings.try(:count), drops: tag.try(:ratings).where("user_id = ? OR is_box_locked is false", self.id).order("rating_like_count desc").limit(3).reject { |drop| hiddenDrops.include? drop.try(:id) }.collect { |drop| {drop_id: drop.try(:id), drop_creator_user_name: drop.try(:user).try(:user_name), drop_creator_name: drop.try(:user).try(:full_name), drop_created_at: drop.try(:created_at), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.try(:user).try(:photo).try(:url), drop_description: drop.try(:comment), is_anonymous_rating: drop.try(:is_anonymous_rating), drop_like_count: drop.try(:rating_like_count), drop_replies_count: drop.try(:comments).try(:count), is_like: (UserRating.where(user_id: self.id, rating_id: drop.try(:id)).try(:last).try(:is_like) || false), drop_hidden_by_users: drop.drop_hidden_by_users} }}) if tag.open_date.present?
    end
  end

  def box_story_hash_structure boxes, exclude_hidden_drops = false, exclude_boxes = false
    if exclude_hidden_drops
      hiddenDrops = self.user_hidden_drops
      notIn = get_tag_ids_to_hide hiddenDrops

      if exclude_boxes and notIn.present?
        boxes = boxes.where('id not in (?)', notIn)
      end
      boxes.collect do |tag|
        {box_id: tag.try(:id), is_drop_story: false, box_creator_name: tag.try(:user).try(:full_name), box_name: tag.try(:tag_line), box_created_at: tag.try(:created_at), sort_created_at: tag.try(:created_at), box_title: tag.try(:tag_title), is_allow_anonymous: tag.try(:is_allow_anonymous), is_flagged: tag.try(:is_flagged), is_locked: tag.try(:is_locked), is_post_to_wall: tag.try(:is_post_to_wall), is_private: tag.try(:is_private), open_date: tag.try(:open_date), close_date: tag.try(:close_date), box_description: tag.try(:tag_description), box_creator_id: tag.try(:user_id), box_creator_image: tag.try(:user).try(:photo).try(:url), box_creator_user_name: tag.try(:user).try(:full_name), box_creator_user_name: tag.try(:user).try(:user_name), is_follower: check_user(tag.try(:user), self), box_expiry: tag.try(:expiry_time), box_total_drops: tag.try(:ratings).try(:count)}.merge({drops_count: tag.ratings.try(:count), drops: tag.try(:ratings).includes(:user, :comments).where("user_id = ? OR is_box_locked = ?", self.id, false).order("rating_like_count DESC").reject { |drop| hiddenDrops.include? drop.try(:id) }.collect { |drop| {drop_id: drop.try(:id), drop_creator_user_name: drop.try(:user).try(:user_name), drop_creator_name: drop.try(:user).try(:full_name), drop_created_at: drop.try(:created_at), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.try(:user).try(:photo).try(:url), drop_description: drop.try(:comment), is_anonymous_rating: drop.try(:is_anonymous_rating), drop_like_count: drop.try(:rating_like_count), drop_replies_count: drop.try(:comments).try(:count), is_like: (UserRating.where(user_id: self.id, rating_id: drop.try(:id)).try(:last).try(:is_like) || false), drop_hidden_by_users: drop.drop_hidden_by_users} }})
      end
    else

      boxes.collect do |tag|
        {box_id: tag.try(:id), is_drop_story: false, box_creator_name: tag.try(:user).try(:full_name), box_name: tag.try(:tag_line), box_created_at: tag.try(:created_at), sort_created_at: tag.try(:created_at), box_title: tag.try(:tag_title), is_allow_anonymous: tag.try(:is_allow_anonymous), is_flagged: tag.try(:is_flagged), is_locked: tag.try(:is_locked), is_post_to_wall: tag.try(:is_post_to_wall), is_private: tag.try(:is_private), open_date: tag.try(:open_date), close_date: tag.try(:close_date), box_description: tag.try(:tag_description), box_creator_id: tag.try(:user_id), box_creator_image: tag.try(:user).try(:photo).try(:url), box_creator_user_name: tag.try(:user).try(:full_name), box_creator_user_name: tag.try(:user).try(:user_name), is_follower: check_user(tag.try(:user), self), box_expiry: tag.try(:expiry_time), box_total_drops: tag.try(:ratings).try(:count)}.merge({drops_count: tag.ratings.try(:count), drops: tag.try(:ratings).includes(:user, :comments).where("user_id = ? OR is_box_locked = ?", self.id, false).order("rating_like_count DESC").limit(3).collect { |drop| {drop_id: drop.try(:id), drop_creator_user_name: drop.try(:user).try(:user_name), drop_creator_name: drop.try(:user).try(:full_name), drop_created_at: drop.try(:created_at), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.try(:user).try(:photo).try(:url), drop_description: drop.try(:comment), is_anonymous_rating: drop.try(:is_anonymous_rating), drop_like_count: drop.try(:rating_like_count), drop_replies_count: drop.try(:comments).try(:count), is_like: (UserRating.where(user_id: self.id, rating_id: drop.try(:id)).try(:last).try(:is_like) || false), drop_hidden_by_users: drop.drop_hidden_by_users} }})
      end
    end

  end

  # Modified By Kamran (Aesquares)
  # Populated tags with relational data such as user, drops and comments of drops
  # @param offset [Integer] Caluclated offset of the pagination
  # @param limit [Integer] Limit value of the function
  # @return [Hash]
  def explore_tab_boxes offset = 0, limit = 30
    #Get the tags and eager load the user and ratings with specified limits and offset
    @tags=Tag.includes(:user).where("close_date is not NULL AND close_date >= ?", DateTime.now).limit(limit).offset(offset)
    #preparing the data to send the response
    box_story_hash_structure @tags, true
  end

  def explore_tab_boxes_count
    Tag.where("close_date is not NULL AND close_date >= ?", DateTime.now).count
  end

  def user_follow_drops
    users = UserFollow.where(follow_id: self.id).collect { |u| u.user_id }
    collect_drops users
    #UserFollow.where(follow_id: self.id).collect{|user| user.try(:user).try(:tags).where(is_private: false).collect{|tag| {box_name: tag.tag_line, box_title: tag.tag_title, box_description: tag.tag_description, box_creator_id: tag.user_id, box_creator_image: tag.try(:user).try(:photo).try(:url), box_creator_user_name: tag.try(:user).try(:full_name), box_creator_user_name: tag.try(:user).try(:user_name), box_expiry: tag.expiry_time, box_total_drops: tag.try(:ratings).try(:count)}.merge({drops: tag.try(:ratings).limit(3).collect{|drop| {drop_creator_user_id: drop.try(:user).try(:user_name), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.user.try(:photo).try(:url), drop_description: drop.comment, drop_like_count: drop.rating_like_count, drop_replies_count: drop.comments.count}}})}}
  end

  def user_not_follow_boxes
    users=UserFollow.where("follow_id != ?", self.id).collect { |u| u.user_id }
    collect_data users
    #users.collect{|user| user.try(:user).try(:tags).where(is_private: false).collect{|tag| {box_name: tag.tag_line, box_title: tag.tag_title, box_description: tag.tag_description, box_creator_id: tag.user_id, box_creator_image: tag.try(:user).try(:photo).try(:url), box_creator_user_name: tag.try(:user).try(:full_name), box_creator_user_name: tag.try(:user).try(:user_name), box_expiry: tag.expiry_time, box_total_drops: tag.try(:ratings).try(:count)}.merge({drops: tag.try(:ratings).limit(3).collect{|drop| {drop_creator_user_id: drop.try(:user).try(:user_name), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.user.try(:photo).try(:url), drop_description: drop.comment, drop_like_count: drop.rating_like_count, drop_replies_count: drop.comments.count}}})}}
  end

  def collect_data users
    array = Array.new
    if users.present?
      users.each do |user|
        user.try(:user).try(:tags).where(is_private: false).each do |tag|
          array << {box_id: tag.id, is_drop_story: false, box_name: tag.tag_line, box_description: tag.tag_description, is_allow_anonymous: tag.try(:is_allow_anonymous), is_flagged: tag.try(:is_flagged), is_locked: tag.try(:is_locked), is_post_to_wall: tag.try(:is_post_to_wall), is_private: tag.try(:is_private), open_date: tag.try(:open_date), close_date: tag.try(:close_date), box_creator_id: tag.user_id, box_creator_image: tag.try(:user).try(:photo).try(:url), box_creator_name: tag.try(:user).try(:full_name), box_creator_user_name: tag.try(:user).try(:user_name), is_follower: check_user(tag.try(:user), self), box_created_at: tag.created_at, sort_created_at: tag.created_at, box_expiry: tag.expiry_time, box_total_drops: tag.try(:ratings).try(:count)}
        end
      end
    end
    array
  end

  def collect_drops_data users
    array = Array.new
    if users.present?
      users.each do |user|
        user.try(:user).try(:tags).where(is_private: false).each do |tag|
          if tag.try(:ratings).where("user_id != ? AND user_id NOT IN(?)", self.try(:id), following_users).try(:count) > 0
            array << {box_id: tag.id, is_drop_story: false, box_name: tag.tag_line, box_description: tag.tag_description, is_allow_anonymous: tag.try(:is_allow_anonymous), is_flagged: tag.try(:is_flagged), is_locked: tag.try(:is_locked), is_post_to_wall: tag.try(:is_post_to_wall), is_private: tag.try(:is_private), open_date: tag.try(:open_date), close_date: tag.try(:close_date), box_creator_id: tag.user_id, box_creator_image: tag.try(:user).try(:photo).try(:url), box_creator_name: tag.try(:user).try(:full_name), box_creator_user_name: tag.try(:user).try(:user_name), is_follower: check_user(tag.try(:user), self), box_created_at: tag.created_at, sort_created_at: tag.created_at, box_expiry: tag.expiry_time, box_total_drops: tag.try(:ratings).try(:count)}.merge({drops: tag.try(:ratings).where("user_id != ? AND user_id NOT IN(?)", self.id, following_users).limit(3).collect { |drop| {drop_id: drop.id, drop_creator_user_name: drop.try(:user).try(:user_name), drop_creator_name: drop.try(:user).try(:full_name), drop_created_at: drop.try(:created_at), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.user.try(:photo).try(:url), drop_description: drop.comment, drop_like_count: drop.rating_like_count, drop_replies_count: drop.try(:comments).try(:count), is_anonymous_rating: drop.try(:is_anonymous_rating), is_like: (UserRating.where(user_id: self.id, rating_id: drop.id).try(:last).try(:is_like) || false)} }})
          end
        end
      end
    end
    array
  end

  def collect_drops users
    array = Array.new
    if users.present?
      users.each do |user|
        user.try(:user).try(:ratings).each do |drop|
          array << {box_id: drop.try(:tag).try(:id), is_drop_story: true, box_name: drop.try(:tag).try(:tag_line),
                    box_description: drop.try(:tag).try(:tag_description), is_allow_anonymous: drop.try(:tag).try(:is_allow_anonymous), is_flagged: drop.try(:tag).try(:is_flagged),
                    is_locked: drop.try(:tag).try(:is_locked), is_post_to_wall: drop.try(:tag).try(:is_post_to_wall), is_private: drop.try(:tag).try(:is_private), open_date: drop.try(:tag).try(:open_date),
                    close_date: drop.try(:tag).try(:close_date), box_creator_id: drop.try(:tag).try(:user_id), box_creator_image: drop.try(:tag).try(:user).try(:photo).try(:url), sort_created_at: drop.try(:created_at),
                    box_creator_name: drop.try(:tag).try(:user).try(:full_name), box_creator_user_name: drop.try(:tag).try(:user).try(:user_name), is_follower: check_user(drop.try(:tag).try(:user), self),
                    box_created_at: drop.try(:tag).try(:created_at), box_expiry: drop.try(:tag).try(:expiry_time), box_total_drops: drop.try(:tag).try(:ratings).try(:count)}.merge({drops: [{drop_id: drop.try(:id), sort_created_at: drop.try(:created_at), drop_creator_user_name: drop.try(:user).try(:user_name), drop_creator_name: drop.try(:user).try(:full_name), drop_created_at: drop.try(:created_at), drop_creator_user_id: drop.try(:user_id), drop_creator_profile_image: drop.try(:user).try(:photo).try(:url), drop_description: drop.try(:comment), drop_like_count: drop.try(:rating_like_count), drop_replies_count: drop.try(:comments).try(:count), is_anonymous_rating: drop.try(:is_anonymous_rating), is_like: (UserRating.where(user_id: self.id, rating_id: drop.try(:id)).try(:last).try(:is_like) || false)}]})
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
    if user.present?
      following = UserFollow.where(follow_id: current_user.try(:id), user_id: user.try(:id), is_approved: true)
      if following.present?
        true
      else
        false
      end
    else
      false
    end
  end

  def check_user_following(user, current_user)
    if user.present?
      following = UserFollow.where(follow_id: current_user.try(:id), user_id: user.try(:id), is_approved: true)
      if following.present?
        true
      else
        false
      end
    end
  end

  def check_user_follower(user, current_user)
    if user.present?
      following = UserFollow.where(follow_id: current_user.try(:id), user_id: user.try(:id), is_approved: true)
      if following.present?
        true
      else
        false
      end
    end
  end
end
