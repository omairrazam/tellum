class ApplicationController < ActionController::Base
  protect_from_forgery

  ApplicationController.class_eval do
    %w(index new edit show update destroy create).each do |a|
      define_method a do
        render json: { message: "#{a} not found" }
      end
    end
  end

  def set_admin_timezone
    #Time.zone = current_user.time_zone if current_user
    Time.zone = 'Eastern Time (US & Canada)'
  end

  private

  def validate_request_format
    if params[:request].blank?
      get_api_message "403","Invalid request format."
      render_response
      return false
    end
  end

  def get_model_error(obj)
    error_messages = Array.new
    obj.errors.full_messages.each{|msg|
      error_messages << msg.to_s
    }
    error_messages
  end

  def get_api_message code,details
    @message = Message.find_by_code(code)
    @message.custom_message = details
  end

  def render_response
    render :json => {:response=>{:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}
  end

  def render_errors
    error = Array.new
    error.push @errors.first
    render :json => {:response=>{:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,:errors=>error}}
  end


end
