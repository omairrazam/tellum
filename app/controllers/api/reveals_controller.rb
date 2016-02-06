class Api::RevealsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_user!
  def reveal_yourself
    current_user = User.find_by_authentication_token(params[:auth_token])
    receiver_id = Rating.find(params[:request][:rating_id])
    reveal = Reveal.where user_id: current_user.id, rating_id: params[:request][:rating_id], receiver_id: receiver_id.try(:user_id)
    if reveal.last.present?
      get_api_message "403","You already requested the same user."
      return render_response
    else
      @reveal = Reveal.new user_id: current_user.id, rating_id: params[:request][:rating_id], receiver_id: receiver_id.try(:user_id)
      if @reveal.save
        badge_count = receiver_id.try(:user).try(:badge_count) + 1
        receiver_id.try(:user).update_attributes badge_count: badge_count
        APNS.send_notification(receiver_id.try(:user).try(:device_token), alert: "#{current_user.try(:full_name)} revealed on #{receiver_id.try(:tag).try(:tag_line)}",badge: badge_count, sound: "default" )
        Notification.create user_id: receiver_id.try(:user_id), reveal_id: @reveal.id, object_name: "Reveal Request", rating_id: params[:request][:rating_id], sender_id: current_user.id
        #"Reveal Viewed"
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @reveal, notice: 'Reveal request sent successfully' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :reveal => @reveal}  } }
          #.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!(user: @reveal.user.hide_fields, rating: @reveal.rating.attributes)
        end
      else
        get_api_message "501","Invalid Request"
        respond_to do |format|
          format.html { redirect_to @reveal, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :reveal => @reveal.errors }}}
        end
      end
    end
  end
  def reveal_status
    @reveal = Reveal.find params[:request][:reveal_id]
    @notification = Notification.find_by_reveal_id params[:request][:reveal_id]
    if @notification.present?
      if @notification.update_attributes status: params[:request][:status]
        Notification.create(user_id: @reveal.user_id, reveal_id: @reveal.id, object_name: "Reveal Viewed Accepted",
                            rating_id: @reveal.rating_id, sender_id: @reveal.receiver_id) if params[:request][:status] == true
        badge_count = @reveal.try(:user).try(:badge_count) + 1
        @reveal.try(:user).update_attributes badge_count: badge_count
        if params[:request][:status] == true
          APNS.send_notification(@reveal.user.try(:device_token), alert: "Your reveal has been accepted",badge: badge_count, sound: "default" )
        else
          APNS.send_notification(@reveal.user.try(:device_token), alert: "Your reveal has been rejected",badge: badge_count, sound: "default" )
        end
        @reveal.update_attributes status: params[:request][:status]
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @reveal, notice: 'Reveal status updated successfully' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :reveal => @reveal }}   }
        end
      else
        if !@notification.errors.empty?
          get_api_message "501","Invalid Request"
          @errors=get_model_error(@notification)
          return render_errors
        end
        get_api_message "404","Not Found"
        return render_response
      end
    end
  end
  def revealed_user
    if params[:auth_token].present? && params[:notification_id]
      notification = Notification.find params[:notification_id]
      @reveal = Reveal.find notification.reveal_id
      if @reveal.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @reveal, notice: 'Reveal status updated successfully' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :revealed_user => @reveal.rating.user.hide_fields }}  }
        end
        notification.update_attributes(is_view: true)
      else
        get_api_message "404","Not Found"
        return render_response
      end
    else
      get_api_message "501","Invalid Request"
      return render_response
    end
  end

end
