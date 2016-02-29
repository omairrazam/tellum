class Api::NotificationsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_user!

  def all_notifications
    @user = User.find_by_authentication_token(params[:auth_token])
    @notifications = Notification.where("user_id = ? AND is_deleted = ?", @user.id, false).order("created_at desc") if @user.present?
  end
  def update
    @user = User.find_by_authentication_token params[:auth_token]
    @notification = Notification.find_by_id(params[:request][:id]) if @user.present?
  end
  # def all_notifications
  #   user = User.find_by_authentication_token(params[:auth_token])
  #   if params[:date].present? && params[:auth_token].present?
  #     @reveal = Notification.where("updated_at <= ? AND user_id = ? AND status is NULL AND is_view is NULL", params[:date].to_datetime.to_s(:db), user.id).order("created_at desc").limit(30)
  #     #Reveal.where("updated_at <= ? AND user_id = ?", params[:date].to_datetime.to_s(:db), current_user).order("updated_at desc").limit(30)
  #     if @reveal.present?
  #       get_api_message "200","success"
  #       respond_to do |format|
  #         format.html { redirect_to @reveal, notice: 'Reveal found successfully' }
  #         format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :notifications => @reveal.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!( build_hash(t,user))}}  } }
  #       end
  #       @reveal.each do |reveal|
  #         reveal.update_attributes is_seen: true
  #       end
  #     else
  #       get_api_message "404","Not Found"
  #       return render_response
  #     end
  #   elsif params[:auth_token].present?
  #     @reveal = Notification.where("user_id = ? AND status is NULL AND is_view is NULL", user.id).order("created_at desc").limit(30)
  #     if @reveal.present?
  #       get_api_message "200","success"
  #       respond_to do |format|
  #         format.html { redirect_to @reveal, notice: 'Reveal found successfully' }
  #         format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :notifications => @reveal.collect { |t| t.try(:attributes).keep_if { |k, v| !["user_id"].include?(k)  }.merge!( build_hash(t,user))}}  } }
  #       end
  #       @reveal.each do |reveal|
  #         reveal.update_attributes is_seen: true
  #       end
  #     else
  #       get_api_message "404","Not Found"
  #       return render_response
  #     end
  #   else
  #     get_api_message "501","Invalid Request"
  #     return render_response
  #   end
  # end
  def all_notifications_PTR
    user = User.find_by_authentication_token(params[:auth_token])
    if params[:date].present? && params[:auth_token].present?
      @reveal = Notification.where("updated_at BETWEEN  ? AND ? AND user_id = ? AND status is NULL AND is_view is NULL",params[:date], DateTime.now, user.id).order("created_at desc").limit(30)
      if @reveal.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @reveal, notice: 'Reveal found successfully' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :notifications => @reveal.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!( build_hash(t,user))}}  } }
        end
        @reveal.each do |reveal|
          reveal.update_attributes is_seen: true
        end
      else
        get_api_message "404","Not Found"
        return render_response
      end
    else
      get_api_message "501","Invalid Request"
      return render_response
    end
  end
  def all_notifications_count
    if params[:auth_token].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @reveal = Notification.where("user_id = ?", current_user.id) if current_user.present?
      if @reveal.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @reveal, notice: 'Reveal status updated successfully' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :notifications_count =>  {total: @reveal.count, unread: @reveal.select{|notify| notify if notify.is_seen.nil?  }.count}}  } }
        end
      else
        get_api_message "404","Not Found"
        return render_response
      end
    else
      get_api_message "501","Invalid Request"
      return render_response
    end
  end
  private
  def rating_hash(notification, current_user)
    Rating.find(notification.rating_id).attributes.keep_if { |k, v| !["tag_id", "user_id"].include?(k)}.merge!(tag_line: Tag.find_by_id(Rating.find(notification.rating_id).tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(Rating.find(notification.rating_id).tag_id).average_rating, total_rating: Tag.find_by_id(Rating.find(notification.rating_id).tag_id).total_rating, user: check_user(Tag.find_by_id(Rating.find(notification.rating_id).tag_id).user, current_user) }), comments: Rating.find(notification.rating_id).comments.count, user: Rating.find(notification.rating_id).user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: notification.rating_id).try(:last).try(:is_like) || false )  ) if Rating.find_by_id(notification.rating_id).present?
  end
  def check_user(user, current_user)
    follower = UserFollow.where(follow_id: user.id, user_id: current_user.try(:id), is_approved: true)
    following = UserFollow.where(follow_id: current_user.id, user_id: user.try(:id), is_approved: true)
    user[:is_follower] = true if follower.present?
    user[:is_following] = true if following.present?
    user
  end
  def notification_object t
    if t.reveal_id.nil?
      Reveal.find(t.try(:reveal_id))
    elsif t.rating_id.present?
      Rating.find(t.try(:rating_id))
    end
  end
  def build_hash(t, user)
    unless t.try(:reveal_id).nil?
      {object: Reveal.find(t.try(:reveal_id)).attributes.keep_if { |k, v| !["user_id", "rating_id"].include?(k)  }.merge!(user: Reveal.find(t.try(:reveal_id)).try(:user).try(:hide_fields), rating: rating_hash(t, user))}
    else
      #{object: rating_hash(t, user)}
      if Rating.find_by_id(t.rating_id).present?
        {object: Rating.find_by_id(t.try(:rating_id)).attributes.keep_if { |k, v| !["tag_id", "user_id"].include?(k)}.merge!(tag_line: Tag.find_by_id(Rating.find(t.rating_id).try(:tag_id)).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(Rating.find(t.rating_id).tag_id).average_rating, total_rating: Tag.find_by_id(Rating.find(t.rating_id).tag_id).total_rating, user: check_user(Tag.find_by_id(Rating.find(t.rating_id).tag_id).user, user) }), comments: Rating.find(t.rating_id).comments.count)}
        #{object: Rating.find_by_id(t.try(:rating_id)).attributes.keep_if { |k, v| !["tag_id", "user_id"].include?(k)}.merge!(tag_line: Tag.find_by_id(Rating.find(t.rating_id).try(:tag_id)).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(Rating.find(t.rating_id).tag_id).average_rating, total_rating: Tag.find_by_id(Rating.find(t.rating_id).tag_id).total_rating, user: check_user(Tag.find_by_id(Rating.find(t.rating_id).tag_id).user, user) }), comments: Rating.find(t.rating_id).comments.count, user: User.find(t.sender_id), is_like: ( UserRating.where(user_id: user.id, rating_id: t.rating_id).try(:last).try(:is_like) || false )  )}
      else
        {object: "not exists"}
      end
    end
  end
end
