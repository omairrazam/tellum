class Api::SessionsController < Api::ApplicationController
  skip_before_filter :verify_authenticity_token
  def create
    if params[:request][:user][:device_token]
      @user = User.authenticate params[:request][:user][:user_name] , params[:request][:user][:password]
      if @user
        if @user.update_attributes(:device_token => params[:request][:user][:device_token])
          get_api_message "200","Created"
          respond_to do |format|
            format.html { redirect_to @user, notice: 'session was successfully created.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user => @user.hide_fields.merge!({followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count}) }  }}
          end
        end
      else
        get_api_message "404","Record not found"
        return render_response
      end
    else
      get_api_message "501","Invalid request"
      return render_response
    end
  end
  def destroy
    if params[:auth_token].present?
      @user=User.find_by_authentication_token(params[:auth_token])
      if @user.present?
        @user.reset_authentication_token!
        @user.update_attribute :device_token, ""
        reset_session
        get_api_message "200","session deleted successfully"
        respond_to do |format|
          #format.html { redirect_to @user, notice: 'session was successfully deleted.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message }  }}
        end
      else
        get_api_message "404","Record not found"
        return render_response
      end
    else
      get_api_message "501","Invalid request"
      return render_response
    end
  end
end
