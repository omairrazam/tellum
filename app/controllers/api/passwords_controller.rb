class Api::PasswordsController < Devise::PasswordsController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :require_no_authentication, only: [:create, :update]

  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
      if successfully_sent?(resource)
        get_api_message "200", "Created"
        respond_to do |format|
          format.html { redirect_to @rating, notice: 'success.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :auth_token => resource.authentication_token}} }
        end
      else
        get_api_message "404", "Email not found"
        respond_to do |format|
          format.html { redirect_to @rating, notice: 'Email not found' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user}} }
        end
      end
  end

  def update
    if params[:reset_password_token]
      self.resource = resource_class.reset_password_by_token(resource_params)
      if resource.errors.empty?
        resource.unlock_access! if unlockable?(resource)
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message(:notice, flash_message) if is_navigational_format?
        get_api_message "200", "updated"
        respond_to do |format|
          format.html { render text: 'Password updated succesfully' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => resource.hide_fields}} }
        end
      else
        get_api_message "501", "invalid request"
        respond_to do |format|
          format.html { render :edit }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message }} }
        end
      end
    else
      @user = current_user
      if @user && @user.valid_password?(params[:request][:user][:old_password])
        @user.update_attributes(password: params[:request][:user][:new_password])
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message(:notice, flash_message) if is_navigational_format?
        get_api_message "200", "updated"
        respond_to do |format|
          format.html { render text: 'Password updated succesfully' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user}} }
        end
      else
        #format.html { redirect_to :edit_user_password, notice: 'Invalid request' }
        get_api_message "501", "invalid request"
        respond_to do |format|
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message }} }
        end
      end
    end
  end

  private
  def resource_name
    params[:action].to_s == "create" ? "request" : super
  end

end
