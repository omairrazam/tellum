class FlaggedBox < ActiveRecord::Base
  before_destroy :check_flagged_box
  attr_accessible :is_flagged, :tag_id, :user_id
  belongs_to :tag, dependent: :destroy
  belongs_to :user
  private
  def check_flagged_box
    FlaggedBox.where(tag_id: self.tag_id).delete_all
  end
end
