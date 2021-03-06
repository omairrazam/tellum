class Api::UserFollowsController < Api::ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_user!

  def create
    current_user = User.find_by_authentication_token(params[:auth_token])
    #user = User.find(params[:request][:user_id])
    #tellum_host = request.host
    @user = UserFollow.where(user_id: params[:request][:user_id], follow_id: current_user.id)
    receiver = User.find_by_id(params[:request][:user_id])
    if !@user.present?
      @user_follow = UserFollow.new(user_id: params[:request][:user_id], follow_id: current_user.id, is_approved: true)
      if User.find_by_id(params[:request][:user_id]).is_public_profile == true
        if @user_follow.save
          APNS.send_notification(receiver.try(:device_token), alert: "#{current_user.try(:full_name)} is now following you.",badge: (receiver.badge_count + 1), sound: "default" )
          Notification.create(user_id: params[:request][:user_id], object_name: "New Follower", sender_id: current_user.id)  if current_user.id != params[:request][:user_id]
          get_api_message "200","You are following the user."
          respond_to do |format|
            format.html { redirect_to @user_follow, notice: 'You are following the user.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id] }} }
          end
          # unless user.email.blank?
          #   FollowUser.follow_user(current_user.id, params[:request][:user_id], tellum_host).deliver
          # end
        else
          if !@user_follow.errors.empty?
            get_api_message "501","Invalid Request"
            @errors=get_model_error(@user)
            return render_errors
          else
            get_api_message "404","User cannot follow."
            return render_response
          end
        end
      else
        UserFollow.create(user_id: params[:request][:user_id], follow_id: current_user.id, is_approved: false)
        Notification.create(user_id: params[:request][:user_id], object_name: "Follow User Request", sender_id: current_user.id)  if current_user.id != params[:request][:user_id]
        APNS.send_notification(receiver.try(:device_token), alert: "#{current_user.try(:full_name)} sent you a follow request.",badge: (receiver.badge_count + 1), sound: "default" )
        #FollowUser.follow_user(current_user.id, params[:request][:user_id], tellum_host).deliver if current_user.email.present?
        get_api_message "405","User request has been sent for approval."
        return render_response
      end
    else
      get_api_message "406","You have already sent a request."
      return render_response
    end
  end
  def follow_users
    request_sent = Array.new
    current_user = User.find_by_authentication_token(params[:auth_token])
    users = params[:request][:user_id].map { |k, v| k[:user_id] }
    users.each do |user|
      @user = UserFollow.where(user_id: user, follow_id: current_user.id)
      if !@user.present?
        @user_follow = UserFollow.new(user_id: user, follow_id: current_user.id)
        if User.find_by_id(user).is_public_profile == true
          @user_follow.save
          request_sent << user
        else
          UserFollow.create(user_id: params[:request][:user_id], follow_id: current_user.id, is_approved: false)
        end
      end
    end
    if request_sent.present?
      get_api_message "200","You are following the users."
      respond_to do |format|
        format.html { redirect_to @user_follow, notice: 'You are following the user.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message }} }
      end
    else
      get_api_message "405","User request has been sent for approval."
      return render_response
    end
  end
  def unfollow_user
    if params[:request][:user_id] && params[:auth_token]
      current_user = User.find_by_authentication_token(params[:auth_token])
      @user_unfollow = UserFollow.where(user_id: params[:request][:user_id], follow_id: current_user.id)
      if @user_unfollow.present?
        @user_unfollow.last.delete
        get_api_message "200","You are unfollowing the user."
        respond_to do |format|
          #format.html { redirect_to @user_unfollow, notice: 'You are unfollowing the user.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id] }} }
        end
      else
        get_api_message "404","User not found."
        return render_response
      end
    else
      get_api_message "501","Invalid Request"
      respond_to do |format|
        #format.html { redirect_to @user_unfollow, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id], :auth_token => params[:request][:auth_token] }} }
      end
    end
  end
  def remove_follower_user
    if params[:request][:user_id] && params[:auth_token]
      current_user = User.find_by_authentication_token(params[:auth_token])
      @user_unfollow = UserFollow.where(follow_id: params[:request][:user_id], user_id: current_user.id)
	    if @user_unfollow.present?
        @user_unfollow.last.delete
        get_api_message "200","You are unfollowing the user."
        respond_to do |format|
          format.html { redirect_to @user_unfollow, notice: 'You are unfollowing the user.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id] }} }
        end
      else
        get_api_message "404","User not found."
        return render_response
      end
    else
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @user_unfollow, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id], :auth_token => params[:request][:auth_token] }} }
      end
    end
  end
  def accept_follow_request
    if params[:request][:user_id].present? && params[:auth_token].present? && !params[:request][:is_approved].nil?
      current_user = User.find_by_authentication_token(params[:auth_token])
      receiver = User.find_by_id(params[:request][:user_id])
      @accept_user_request = UserFollow.find_by_follow_id_and_user_id(params[:request][:user_id], current_user.id)
      if @accept_user_request.present?
        if params[:request][:is_approved] == false
          @accept_user_request.delete
          Notification.where(sender_id: receiver.id, user_id: current_user.id, object_name: "Follow User Request").last.update_attribute :is_deleted, true
          get_api_message "200","You Ignored #{receiver.user_name}'s' friend request."
          respond_to do |format|
            format.html { redirect_to @user_follow, notice: 'You accept a request.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id] }} }
          end
        else
          @accept_user_request.update_attributes is_approved: params[:request][:is_approved]
          Notification.create(user_id: params[:request][:user_id], object_name: "Accpted Follow Request", sender_id: current_user.id)  if current_user.id != params[:request][:user_id]
          APNS.send_notification(receiver.try(:device_token), alert: "#{current_user.try(:full_name)} is accepted your follow request.",badge: (receiver.badge_count + 1), sound: "default" )
          Notification.where(sender_id: receiver.id, user_id: current_user.id, object_name: "Follow User Request").last.update_attribute :is_deleted, true
          get_api_message "200","You accepted friend request."
          respond_to do |format|
            format.html { redirect_to @user_follow, notice: 'You accept a request.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id] }} }
          end
        end
      else
        get_api_message "404","User not found."
        return render_response
      end
    else
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @user_follow, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id], :auth_token => params[:auth_token] }} }
      end
    end
  end
  def send_follow_request
    if params[:request][:user_id] && params[:auth_token] && params[:request][:is_accepted]
      current_user = User.find_by_authentication_token(params[:auth_token])
      @accept_user_request = FollowUser.new user_id: params[:request][:user_id], follow_id: current_user.id, is_accepted: params[:is_accepted]
      if @accept_user_request.save
        get_api_message "200","You sent a request."
        respond_to do |format|
          format.html { redirect_to @user_unfollow, notice: 'You sent a request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id] }} }
        end
      else
        get_api_message "404","User not found."
        return render_response
      end
    else
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @user_unfollow, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id], :auth_token => params[:request][:auth_token] }} }
      end
    end
  end
  def remove_following_request
    if params[:auth_token].present? && params[:request][:user_id].present?
      current_user = User.find_by_authentication_token params[:auth_token]
      @unfollow_user = UserFollow.where(user_id: params[:request][:user_id], follow_id: current_user.id)
      if @unfollow_user.present?
        @unfollow_user.last.delete
        get_api_message "200","You are no longer following the user . #{@unfollow_user.count}"
        respond_to do |format|
          format.html { redirect_to @unfollow_user, notice: "User is no longer follow you." }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id] }} }
        end
      else
        get_api_message "404","User not found."
        return render_response
      end
    else
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @user_unfollow, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id], :auth_token => params[:auth_token] }} }
      end
    end
  end
  def my_followers
    if params[:auth_token].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @myfollowers, @follow = UserFollow.where(:user_id => current_user.id).order("created_at desc"), Array.new
      @myfollowers.each do |user|
        #@follow.push User.find_by_id(user.follow_id).hide_fields.merge!({is_approved: user.is_approved})
         u_f = User.find_by_id(user.follow_id)
        if u_f.present?
          @follow.push u_f.hide_fields.merge!({is_approved: user.is_approved})
        end
      end
      if @follow.present?
        get_api_message "200","Followers of mine."
        respond_to do |format|
          format.html { redirect_to @follow_user, notice: 'Followers of mine.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  followers: @follow.each { |user| check_user_hash(user, current_user)} } } }
        end
      else
        get_api_message "404","User not found."
        return render_response
      end
    else
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @unuser_unfollow, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id], :auth_token => params[:auth_token] }} }
      end
    end
  end
  def followers_of_user
    if params[:auth_token].present? && params[:user_id].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @follow_user, @follow = UserFollow.where(user_id: params[:user_id], is_approved: true).order("created_at desc"), Array.new
      @follow_user.each do |user|
        @follow.push User.find_by_id(user.follow_id)
      end
      if @follow.present?
        get_api_message "200","Follower of users."
        respond_to do |format|
          format.html { redirect_to @follow_user, notice: 'Followers of user.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  followers: @follow.each { |user| check_user(user, current_user).hide_fields} }} }
        end
      else
        get_api_message "404","User not found."
        return render_response
      end
    else
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @unuser_unfollow, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id], :auth_token => params[:auth_token] }} }
      end
    end
  end
  def my_followings
#debugger
    if params[:auth_token].present?
      #current_user = User.find_by_authentication_token("mCvdyZUEsutd7jjqxPbu")
      
      current_user = User.find_by_authentication_token(params[:auth_token])
      @myfollowers, @follow = UserFollow.where(:follow_id => current_user.id).order("created_at desc"), Array.new
      if @myfollowers.present?
        #debugger
        @myfollowers.each do |user|
          u_f = User.find_by_id(user.user_id)
          if u_f.present?
            @follow.push u_f.hide_fields.merge!({is_approved: user.is_approved})
          end

        end
        if @follow.present?
          get_api_message "200","Followings of mine."
          respond_to do |format|
            format.html { redirect_to @follow_user, notice: 'Followings of mine.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  followings: @follow.each { |user| check_user_hash(user, current_user)} }} }
          end
        else
          get_api_message "404","User not found."
          return render_response
        end
      else
        get_api_message "404","User not found."
        return render_response
      end
    else
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @unuser_unfollow, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id], :auth_token => params[:auth_token] }} }
      end
    end

  end
  def followings_of_user
    if params[:auth_token].present? && params[:user_id]
      current_user = User.find_by_authentication_token(params[:auth_token])
      @follow_user, @follow = UserFollow.where(follow_id: params[:user_id], is_approved: true).order("created_at desc"), Array.new
      @follow_user.each do |user|
        @follow.push User.find_by_id(user.user_id)
      end
      if @follow.present?
        get_api_message "200","Followings of user."
        respond_to do |format|
          format.html { redirect_to @follow_user, notice: 'Followings of user.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  followings: @follow.each { |user| check_user(user, current_user).hide_fields} }} }
        end
      else
        get_api_message "404","User not found."
        return render_response
      end
    else
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @unuser_unfollow, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message,  :user_id => params[:request][:user_id], :auth_token => params[:auth_token] }} }
      end
    end
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
  def check_user_hash(user, current_user)
    follower = UserFollow.where(follow_id: user["id"], user_id: current_user.id, is_approved: true)
    following = UserFollow.where(follow_id: current_user.id, user_id: user["id"], is_approved: true)
    if follower.present?
      user[:is_follower] = true
    end
    if following.present?
      user[:is_following] = true
    end
    user
  end
end
