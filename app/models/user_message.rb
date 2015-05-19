class UserMessage < ActiveRecord::Base
   attr_accessible :message, :sender_id, :receiver_id
  belongs_to :receiver, :class_name => "User", :foreign_key => "receiver_id"
end
