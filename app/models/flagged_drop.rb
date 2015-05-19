class FlaggedDrop < ActiveRecord::Base
  before_destroy :check_flagged_drop
  attr_accessible :is_flagged, :rating_id, :user_id
  belongs_to :user
  belongs_to :rating, dependent: :destroy
  private
  def check_flagged_drop
    FlaggedDrop.where(rating_id: self.rating_id).delete_all
  end
end
