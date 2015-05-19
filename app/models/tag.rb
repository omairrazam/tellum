class Tag < ActiveRecord::Base
  attr_accessible :tag_line, :tag_title, :tag_description, :open_date, :close_date, :is_private,
                  :is_allow_anonymous, :is_post_to_wall, :user_id, :is_locked, :updated_time, :rating_id
  attr_accessor :total_rating, :average_rating, :is_tag_line
  belongs_to :user
  has_many :ratings, dependent: :destroy
  #belongs_to :rating
  #belongs_to :follow_user
  belongs_to :notification
  validates_presence_of :tag_line
  #validates_uniqueness_of :tag_line
  validates_presence_of :open_date, if: Proc.new { |u| u.is_locked.present? && u.tag_line.blank? }
  validates_presence_of :close_date, if: Proc.new { |u| u.is_locked.present? && u.tag_line.blank? }
  validates_presence_of :is_private, if: Proc.new { |u| u.is_locked.present? && u.tag_line.blank? }
  validates_presence_of :is_allow_anonymous, if: Proc.new { |u| u.is_locked.present? && u.tag_line.blank? }
  validates_presence_of :is_post_to_wall, if: Proc.new { |u| u.is_locked.present? && u.tag_line.blank? }
  has_one :flagged_box, foreign_key: :tag_id
  def average_rating
    self.ratings.collect(&:rating).map(&:to_f).sum / self.ratings.collect(&:rating).count rescue 0
  end

  def total_rating
    self.ratings.collect(&:rating).count rescue 0
  end

  def find_is_tag_line(current_user)
    s = self
    if self.rating_id.blank?
       {is_tag_line: true,  tag_line: self.attributes.keep_if { |k, v| !["user_id", "rating_id"].include?(k) }.merge!({ user: self.user.try(:hide_fields), total_rating: s.total_rating, average_rating: s.average_rating}) }
    else
      {is_tag_line: false,  rating: s.rating.attributes.merge!(tag_line: s.attributes.keep_if { |k, v| !["user_id", "rating_id"].include?(k) }.merge!({  is_like: UserRating.where(user_id: current_user.id, rating_id: s.rating_id).try(:last).try(:is_like), user: self.user.try(:hide_fields), total_rating: s.total_rating, average_rating: s.average_rating}) )  }
    end
  end

  def find_is_tag_line_most_popular(current_user)
    s = self
    hash1 ={is_tag_line: true,  tag_line: self.attributes.keep_if { |k, v| !["user_id", "rating_id"].include?(k) }.merge!({ user: self.user.try(:hide_fields), total_rating: s.total_rating, average_rating: s.average_rating}) }
    #hash1
    if s.rating_id.present?
      hash2 = {is_tag_line: false,  rating: s.attributes.merge!(tag_line: s.attributes.keep_if { |k, v| !["user_id", "rating_id"].include?(k) }.merge!({ rating: Rating.find(s.rating_id).attributes, is_like: UserRating.where(user_id: current_user.id, rating_id: s.rating_id).try(:last).try(:is_like), user: self.user.try(:hide_fields), total_rating: s.total_rating, average_rating: s.average_rating}) )  }
      hash1.merge!( {rating: hash2} )
    else
      hash1
    end
  end

  def fuck_the_fuckers
    self.total_rating.to_i #+ self.ratings.map(&:comments).count + self.ratings.map(&:rating_like_count).sum
  end
end
