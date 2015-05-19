class ErrorCode

  attr_accessor :field , :message

  @@codes = { user: 101, user_name: 201, gender: 202, email: 203, password: 204, facebook_user_id: 206, twitter_user_id: 207, device_token: 209, unknown: 213, invalid: 214 }

  def initialize error=nil
    @field , @message = error
  end

  def get_code
    @@codes[@field]
  end

end