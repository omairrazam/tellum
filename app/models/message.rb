class Message < ActiveRecord::Base
  attr_accessible :status, :code, :detail
  attr_accessor :custom_message
end