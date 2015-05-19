class TagErrorCode

  attr_accessor :field , :message

  @@codes = { tag_line: 101, open_date: 201, close_date: 202, is_private: 203, is_allow_anonymous: 204, is_post_to_wall: 205, unknown: 213, invalid: 214 }

  def initialize error=nil
    @field , @message = error
  end

  def get_code
    @@codes[@field]
  end

end