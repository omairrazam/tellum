class Api::UsersController < Api::ApplicationController
  skip_before_filter :verify_authenticity_token

  #modified by aesquares
  #signup user
  def create
    #checking request if the request index/symbol is present and user inside that request is present or not
    if params[:request] && params[:request][:user]
      #if user is present in the request then populate the model object with parameters
      @user = User.new params[:request][:user]
      #check if we can save the users
      if @user.save
        # user created send the response back according to requesting format
        get_api_message "200", "Created"
        respond_to do |format|
          format.html { redirect_to @user, notice: 'User was successfully created.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields.merge!({followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count})}} }
        end
      else
        #check if user has any error message
        if !@user.errors.empty?
          #getting the api message from database
          #also apendding the custom message for response
          get_api_message "501", "Invalid Request"
          #get the errors returned by model validation
          @errors=get_model_error(@user)
          #this method will render the errors
          #i think it should send all the errors in response currently it is send only one the first error
          return render_errors
        else
          #user is unable to get created due to unknown reason and without any error.. really?
          get_api_message "404", "Record could not be created"
          #send the response back
          return render_response
        end
      end
    else
      #if there is no parameters specified or user is not present in the request we will consider this as invalid request
      get_api_message "501", "Invalid Request"
      #send the response back
      return render_response
    end
  end

  def update
    @user = User.find_by_authentication_token(params[:request][:auth_token])
    respond_to do |format|
      if @user.update_attributes(params[:request][:user])
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def facebook_login
    if params[:request][:user][:facebook_user_id].present?
      @user = User.find_by_facebook_user_id(params[:request][:user][:facebook_user_id]) #User.find_by_email(params[:request][:user][:email]) &&
      if @user.nil?
        if params[:request][:user][:email].present?
          @user = User.find_by_email(params[:request][:user][:email])
          if @user.present?
            @user.update_attributes(facebook_user_id: params[:request][:user][:facebook_user_id], device_token: params[:request][:user][:device_token])
            get_api_message "200", "Successful login."
            respond_to do |format|
              format.html { redirect_to @user, notice: 'user was successfully created.' }
              format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields.merge!({:authentication_token => @user.authentication_token, followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count})}} }
            end
          else
            user = User.find_by_user_name(params[:request][:user][:user_name])
            user.present? ? (@user=User.new params[:request][:user].except(:user_name).merge!({skip_password_form: true, user_name: "#{params[:request][:user][:user_name]}#{rand(10)}"})) : (@user = User.new params[:request][:user].merge!({skip_password_form: true}))
            if @user.save
              get_api_message "200", "Created"
              respond_to do |format|
                format.html { redirect_to @user, notice: 'user was successfully created.' }
                format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields.merge!({:authentication_token => @user.authentication_token, followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count})}} }
              end
            else
              if !@user.errors.empty?
                get_api_message "501", "Invalid Request"
                @errors=get_model_error(@user)
                return render_errors
              else
                get_api_message "404", "Record could not be created"
                return render_response
              end
            end
          end
        else
          user = User.find_by_user_name(params[:request][:user][:user_name])
          user.present? ? (@user=User.new params[:request][:user].except(:user_name).merge!({skip_password_form: true, user_name: "#{params[:request][:user][:user_name]}#{rand(10)}"})) : (@user = User.new params[:request][:user].merge!({skip_password_form: true}))
          if @user.save
            get_api_message "200", "Created"
            respond_to do |format|
              format.html { redirect_to @user, notice: 'user was successfully created.' }
              format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields.merge!({:authentication_token => @user.authentication_token, followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count})}} }
            end
          else
            if !@user.errors.empty?
              get_api_message "501", "Invalid Request"
              @errors=get_model_error(@user)
              return render_errors
            else
              get_api_message "404", "Record could not be created"
              return render_response
            end
          end
        end
      elsif @user.present?
        #user_name = User.find_by_user_name(params[:request][:user][:user_name])
        #user = User.find_by_user_name(params[:request][:user][:user_name])
        if @user.update_attribute :device_token, params[:request][:user][:device_token]
          #@user.update_attribute :device_token, params[:request][:user][:device_token]
          get_api_message "200", "updated"
          respond_to do |format|
            format.html { redirect_to @user, notice: 'user was successfully updated.' }
            format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields.merge!({:authentication_token => @user.authentication_token, followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count})}} }
          end
          # elsif @user.update_attributes(facebook_user_id: params[:request][:user][:facebook_user_id], device_token: params[:request][:user][:device_token])
          #   get_api_message "200","updated"
          #   respond_to do |format|
          #     format.html { redirect_to @user, notice: 'user was successfully updated.' }
          #     format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user => @user.hide_fields.merge!({:authentication_token => @user.authentication_token, followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count})} } }
          #   end
        else
          get_api_message "501", "Error"
          respond_to do |format|
            format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @user.errors.messages.collect { |key, value| "#{key.try(:capitalize)} #{value[0]}" }.join(". ")}} }
          end
        end
      else
        get_api_message "501", "Invalid request"
        respond_to do |format|
          format.html { redirect_to @user, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message}} }
        end
      end
    else
      get_api_message "501", "Invalid request"
      respond_to do |format|
        format.html { redirect_to @user, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message}} }
      end
    end
  end

  def twitter_login
    @user = User.find_by_twitter_user_id(params[:request][:user][:twitter_user_id])
    if @user.present?
      if @user.is_password_blank == true
        #@user.update_attribute(:about_me, params[:request][:user][:about_me]) if params[:request][:user][:twitter_user_id].present?
        @user.update_attribute(:gender, params[:request][:user][:gender]) if params[:request][:user][:gender].present?
        get_api_message "200", "auth_token sent"
        respond_to do |format|
          format.html { redirect_to @user, notice: 'Sent authentication token.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields.merge!({:authentication_token => @user.authentication_token, followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count})}} }
        end
      elsif @user.is_password_blank == false
        get_api_message "200", "Please complete your profile first."
        #@user.update_attribute(:about_me, params[:request][:user][:about_me]) if params[:request][:user][:twitter_user_id].present?
        @user.update_attribute(:gender, params[:request][:user][:gender]) if params[:request][:user][:gender].present?
        respond_to do |format|
          format.html { redirect_to @user, notice: 'Complete your profile.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields.merge!({:authentication_token => @user.authentication_token, followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count})}} }
        end
      else
        get_api_message "501", "Invalid request"
        respond_to do |format|
          format.html { redirect_to @user, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user}} }
        end
      end
    else
      user = User.find_by_user_name(params[:request][:user][:user_name])
      user.present? ? ((twitter_user_name = "#{params[:request][:user][:user_name]}#{rand(10)}") && twitter_user_creation(twitter_user_name)) : twitter_user_creation(params[:request][:user][:user_name])
    end
  end

  def twitter_user_creation twitter_user_name
    @user = User.new(params[:request][:user].except!(:user_name).merge!({skip_password_form: true, user_name: twitter_user_name}))
    if @user.save
      get_api_message "200", "User Created but complete your profile first."
      respond_to do |format|
        format.html { redirect_to @user, notice: 'User was successfully created complete your profile.' }
        format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields.merge!({:authentication_token => @user.authentication_token, followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count})}} }
      end
    else
      get_api_message "404", "#{@user.errors}"
      @errors=get_model_error(@user)
      return render_errors
    end
  end

  def profile_completion
    @user = User.find_by_twitter_user_id(params[:request][:user][:twitter_user_id])
    if @user.nil?
      get_api_message "404", "Record not found"
      respond_to do |format|
        format.html { redirect_to @user, notice: 'Record not found.' }
        format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields}} }
      end
    else
      if params[:request][:user][:password]
        if @user.update_attributes params[:request][:user]
          @user.update_attribute(:is_password_blank, true)
          get_api_message "200", "updated attributes succesfully."
          respond_to do |format|
            format.html { redirect_to @user, notice: 'updated attributes.' }
            format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields.merge!({:authentication_token => @user.authentication_token, followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count})}} }
          end
        else
          get_api_message "501", @user.errors
          @errors=get_model_error(@user)
          return render_errors
        end
      else
        if @user.is_password_blank == true
          @user.update_attributes params[:request][:user]
          get_api_message "200", "auth_token sent"
          respond_to do |format|
            format.html { redirect_to @user, notice: 'Sent authentication token.' }
            format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields.merge!({:authentication_token => @user.authentication_token, followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count})}} }
          end
        else
          get_api_message "501", "Profile completion"
          respond_to do |format|
            format.html { redirect_to @user, notice: 'Please complete your profile first.' }
            format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields}} }
          end
        end
      end
    end
  end

  def facebook_profile_completion
    @user = User.find_by_facebook_user_id(params[:request][:user][:facebook_user_id])
    if @user.nil?
      get_api_message "404", "Record not found"
      respond_to do |format|
        format.html { redirect_to @user, notice: 'Record not found.' }
        format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields}} }
      end
    else
      if params[:request][:user][:email]
        @user.update_attributes params[:request][:user].merge!({blank_password: true})
        get_api_message "200", "Updated attributes succesfully."
        respond_to do |format|
          format.html { redirect_to @user, notice: 'Updated attributes.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields.merge!({:authentication_token => @user.authentication_token, followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count})}} }
        end
      else
        unless @user.email.nil?
          @user.update_attributes params[:request][:user].merge!({blank_password: false})
          get_api_message "200", "auth_token sent"
          respond_to do |format|
            format.html { redirect_to @user, notice: 'Sent authentication token.' }
            format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields.merge!({:authentication_token => @user.authentication_token, followers_count: UserFollow.where(user_id: @user.id, is_approved: true).count, followings_count: UserFollow.where(follow_id: @user.id, is_approved: true).count})}} }
          end
        else
          get_api_message "501", "Profile completion"
          respond_to do |format|
            format.html { redirect_to @user, notice: 'Please complete your profile first.' }
            format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields}} }
          end
        end
      end
    end
  end

  def search_user
    if params[:auth_token] && params[:user_name]
      current_user = User.find_by_authentication_token params[:auth_token]
      if params[:user_name].include? "@"
        @user = User.where("user_name like ?", "%#{params[:user_name].split('@')[1]}%")
      else
        @user = User.where("user_name like ? OR full_name like ?", "%#{params[:user_name]}%", "%#{params[:user_name]}%")
      end
      if @user
        get_api_message "200", "User found"
        respond_to do |format|
          format.html { redirect_to @user, notice: 'Found user successfully.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, users: @user.each { |user| check_user(user, current_user).hide_fields }}} }
        end
      else
        get_api_message "404", "User not found"
        respond_to do |format|
          format.html { redirect_to @user, notice: 'User not found.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, user: @user}} }
        end
      end
    else
      get_api_message "501", "Invalid request"
      respond_to do |format|
        format.html { redirect_to @user, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user}} }
      end
    end
  end

  def user_detail
    if params[:auth_token] && params[:user_id]
      current_user = User.find_by_authentication_token(params[:auth_token])
      @user = User.find_by_id(params[:user_id])
      if @user
        get_api_message "200", "User found"
        respond_to do |format|
          format.html { redirect_to @user, notice: 'Found user successfully.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :user => @user.hide_fields.merge!({is_follower: check_is_follower(@user, current_user).is_follower, is_following: check_is_following(@user, current_user), followers_count: follower_count(@user), followings_count: following_count(@user)})}} }
        end
      else
        get_api_message "404", "User not found"
        respond_to do |format|
          format.html { redirect_to @user, notice: 'User not found.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message}} }
        end
      end
    else
      get_api_message "501", "Invalid request"
      respond_to do |format|
        format.html { redirect_to @user, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message}} }
      end
    end
  end

  def my_profile
    if params[:auth_token]
      @user = User.find_by_authentication_token params[:auth_token]
      if @user
        get_api_message "200", "User found"
        respond_to do |format|
          format.html { redirect_to @user, notice: 'Found user successfully.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, user: @user.hide_fields.merge!({followers_count: my_follower_count(@user), followings_count: my_following_count(@user)})}} }
        end
      else
        get_api_message "404", "User not found invalid auth_token"
        respond_to do |format|
          format.html { redirect_to @user, notice: 'User not found.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message}} }
        end
      end
    else
      get_api_message "501", "Invalid request"
      respond_to do |format|
        format.html { redirect_to @user, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message}} }
      end
    end
  end

  def edit_profile
    @user = User.find_by_authentication_token(params[:auth_token])
    before_update_user_email = @user.email
    if @user.present? && @user.update_attributes(params[:request][:user])
      if params[:request][:user][:email].present?
        if before_update_user_email != params[:request][:user][:email]
          @user.update_attribute(:confirmed_at, "nil")
          @user.resend_generate_confirmation_token
          @user.update_attribute(:is_email_confirmed, false)
          @user.send_reconfirmation_instructions
        end
      end
      get_api_message "200", "User updated"
      respond_to do |format|
        format.html { redirect_to @user, notice: 'Edit profile successfully.' }
        format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, user: @user}} }
      end
    else
      if !@user.errors.empty?
        get_api_message "501", "Invalid Request"
        @errors=get_model_error(@user)
        return render_errors
      else
        get_api_message "501", "Invalid request"
        respond_to do |format|
          format.html { redirect_to @user, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :auth_token => params[:auth_token]}} }
        end
      end
    end
  end

  def send_confirmation_email_again
    if params[:auth_token].present?
      @user = User.find_by_authentication_token(params[:auth_token])
      if @user.is_email_confirmed == false
        @user.update_attribute(:confirmed_at, "nil")
        @user.resend_generate_confirmation_token
        @user.send_confirmation_instructions
        get_api_message "200", "Confirmation Email sent successfully"
        respond_to do |format|
          #format.html { redirect_to @user, notice: 'Email sent successfully.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message}} }
        end
      else
        get_api_message "201", "User is already confirmed."
        respond_to do |format|
          #format.html { redirect_to @user, notice: 'User is already confirmed.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message}} }
        end
      end
    else
      get_api_message "501", "Invalid request"
      respond_to do |format|
        #format.html { redirect_to @user, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message}} }
      end
    end
  end

  def check_user_followings
    current_user = User.find_by_authentication_token params[:auth_token]
    @user = UserFollow.new
    @user_following = @user.user_following params[:request][:user][:users], params[:auth_token]
    @users = @user_following.collect { |user| user.hide_fields.merge!({is_follower: check_is_follower(user, current_user).is_follower, is_following: check_is_following(user, current_user)}) } if @user_following.present?
  end

  
  def twitter_or_facebook_users
    #debugger
    @user = User.find_by_authentication_token params[:auth_token]

    ids = params[:request][:ids]
    tellum_followers_ids   = @user.user_follows.pluck(:follow_id)

    if params[:request][:facebook_ids].present?
      facebook_followers_ids = User.where( :facebook_user_id => ids).pluck(:id)
      final_ids = facebook_followers_ids - tellum_followers_ids
      @users = User.where(:id => final_ids)
    else
      twitter_followers_ids = User.where( :twitter_user_id => ids).pluck(:id)
      final_ids = twitter_followers_ids - tellum_followers_ids
      @users    = User.where(:id => final_ids)
    end
    #params[:request][:facebook_ids]? (@users = User.where("facebook_user_id IN (?)", params[:request][:ids])) : (@users = User.where("twitter_user_id IN (?)", params[:request][:ids]))

    #params[:request][:facebook_ids] == 1 ? (@users = User.where("facebook_user_id IN (?)", params[:request][:ids])) : (@users = User.where("twitter_user_id IN (?)", params[:request][:ids]))
  end

  def update_badge_count
    @user = User.find_by_authentication_token(params[:auth_token])
    @user.update_attribute :badge_count, 0 if @user.present?
  end

  private
  def check_user(user, current_user)
    follower = UserFollow.where(follow_id: user.id, user_id: current_user.id, is_approved: true)
    following = UserFollow.where(follow_id: current_user.id, user_id: user.id, is_approved: true)
    if follower.present?
      user[:is_follower] = true
    end
    if following.present?
      user[:is_following] = true
    end
    user
  end

  def check_is_follower(user, current_user)
    follower = UserFollow.where(follow_id: user.id, user_id: current_user.id, is_approved: true)
    if follower.present?
      user[:is_follower] = true
    end
    user
  end

  def check_is_following(user, current_user)
    following = UserFollow.where(follow_id: current_user.id, user_id: user.id, is_approved: true)
    if following.present?
      user[:is_following] = true
    end
    user.is_following
  end

  def follower_count(user)
    UserFollow.where(user_id: user.id, is_approved: true).count
  end

  def following_count(user)
    UserFollow.where(follow_id: user.id, is_approved: true).count
  end

  def my_follower_count(user)
    UserFollow.where(user_id: user.id).count
  end

  def my_following_count(user)
    UserFollow.where(follow_id: user.id).count
  end

end
