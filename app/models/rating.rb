class Rating < ActiveRecord::Base
  mount_uploader :audio, AudioUploader
  attr_accessible :rating, :tag_id, :sub_rating, :comment, :is_anonymous_rating,
                  :is_post_to_wall, :rating_like_count, :rating_unlike_count, :user_id, :audio, :audio_duration, :audio_file_url, :reveal_id,
                  :is_box_locked, :sort_date
  #has_many :tags
  has_many :notifications, dependent: :destroy, foreign_key: :rating_id
  has_many :comments, :dependent => :destroy
  belongs_to :user
  has_many :reveal
  has_many :user_ratings
  has_one :flagged_drop, foreign_key: :rating_id
  belongs_to :tag
  has_many :commenters, source: :user, through: :comments
  has_many :rating_hide_by
  has_many :drop_hidden_by_users, source: :user, through: :rating_hide_by
  #validates_presence_of :rating
  #validates_presence_of :sub_rating
  validates :is_anonymous_rating, :inclusion => {:in => [true, false]}
  validates :is_post_to_wall, :inclusion => {:in => [true, false]}


  def most_popular_order
    self.comments.count + self.rating_like_count
  end

  def as_json(options=nil)
    if options.present?
      s = super(options.reverse_merge(except: :audio))
      s[:audio] = custom_audio_url
      s
    end
  end

  def custom_audio_url
    self.try(:audio).try(:url)
  end
  
  #def attributes
    #debugger
    #s = super
    #s.merge!(audio:self.custom_audio_url.to_s)
    #s.keep_if {|t| t.to_s != "audio" }.merge!( audio: self.custom_audio_url )
  #end
end
