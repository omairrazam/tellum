class Api::CommentsController < Api::ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_user!

  def create
    current_user = User.find_by_authentication_token(params[:auth_token])
    @comment = Comment.new(:comment => params[:request][:comment], :rating_id => params[:request][:rating_id],
                           :user_id => current_user.id, :is_anonymous_comment => params[:request].try(:[], :is_anonymous_comment))
    @user = current_user.id
    if @comment.save
      rating_creator_user_id = Rating.find(params[:request][:rating_id])
      badge_count = rating_creator_user_id.try(:user).try(:badge_count) + 1
      rating_creator_user_id.try(:user).update_attributes badge_count: badge_count
      unless rating_creator_user_id.try(:user).id == @user
        APNS.send_notification(rating_creator_user_id.try(:user).try(:device_token), alert: "#{current_user.try(:full_name)} replied to your comment in #{rating_creator_user_id.try(:tag).try(:tag_line)}", badge: badge_count, sound: "default")
        if @comment.is_anonymous_comment
          Notification.create(user_id: rating_creator_user_id.try(:user).id, comment_id: @comment.id, object_name: "Comment", sender_id: @user, rating_id: rating_creator_user_id.id, is_anonymous_user: true)
        else
          Notification.create(user_id: rating_creator_user_id.try(:user).id, comment_id: @comment.id, object_name: "Comment", sender_id: @user, rating_id: rating_creator_user_id.id, is_anonymous_user: false)
        end
      end
      #send the notification here in every case
      # push_notifications = []
      commenters = rating_creator_user_id.commenters.uniq
      commenters.each do |commenter|
        if commenter.id != current_user.id && commenter.id != rating_creator_user_id.try(:user).id
          if @comment.is_anonymous_comment
            Notification.create(user_id: commenter.id, comment_id: @comment.id, object_name: "Comment", sender_id: @user, rating_id: rating_creator_user_id.id, is_anonymous_user: true)
            APNS.send_notification(commenter.try(:device_token), alert: "Anonymous also replied to Anonymous's comment in #{rating_creator_user_id.try(:tag).try(:tag_line)}.", badge: badge_count, sound: "default")
          else
            Notification.create(user_id: commenter.id, comment_id: @comment.id, object_name: "Comment", sender_id: @user, rating_id: rating_creator_user_id.id, is_anonymous_user: false)
            APNS.send_notification(commenter.try(:device_token), alert: "#{current_user.try(:full_name)} also replied to #{rating_creator_user_id.try(:user).try(:full_name)}'s comment in #{rating_creator_user_id.try(:tag).try(:tag_line)}.", badge: badge_count, sound: "default")
          end
        end
      end
      # if push_notifications.size > 0
      #   APNS.send_notifications(push_notifications)
      # end
      get_api_message "200", "Created"
      respond_to do |format|
        #@comment.update_attribute :created_at, (@comment.created_at - 9.minutes)
        format.html { redirect_to @comment, notice: 'Comment was successfully created.' }
        format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :comment => @comment.attributes.keep_if { |k, v| k != "user_id" }.merge!({user: @comment.user})}} }
      end
    else
      unless @comment.errors.empty?
        get_api_message "501", "Invalid Request"
        @errors=get_model_error(@comment)
        return render_errors
      else
        get_api_message "404", "Comment could not be created"
        return render_response
      end
    end

  end

  def comments_rating
    if params[:rating_id].present? && params[:auth_token].present? && params[:date].present?
      @comment = Comment.where("rating_id = ? AND updated_at < ?", params[:rating_id], params[:date]).order("updated_at desc")
      if @comment.present?
        get_api_message "200", "Created"
        respond_to do |format|
          format.html { redirect_to @comment, notice: 'Comments was successfully found.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :comment => @comment.collect { |t| t.attributes.keep_if { |k, v| k != "user_id" }.merge!({user: t.user}) }}} }
        end
      else
        get_api_message "404", "no comment found for the given rating_id"
        respond_to do |format|
          format.html { redirect_to @comment, notice: 'not found.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message}} }
        end
      end
    else
      if params[:rating_id].present? && params[:auth_token].present?
        @comment = Comment.where(rating_id: params[:rating_id]).order("updated_at desc")
        if @comment.present?
          get_api_message "200", "Created"
          respond_to do |format|
            format.html { redirect_to @comment, notice: 'Comment was successfully created.' }
            format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :comment => @comment.collect { |t| t.attributes.keep_if { |k, v| k != "user_id" }.merge!({user: t.user}) }}} }
          end
        else
          get_api_message "404", "no comment found for the given rating_id"
          respond_to do |format|
            format.html { redirect_to @comment, notice: 'not found.' }
            format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message}} }
          end
        end
      else
        get_api_message "501", "Invalid Request"
        respond_to do |format|
          format.html { redirect_to @comment, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :rating_id => params[:rating_id], :auth_token => params[:auth_token]}} }
        end
      end
    end
  end

  def comments_rating_PTR
    if params[:rating_id].present? && params[:auth_token].present? && params[:date].present?
      @comment = Comment.where("rating_id = ? AND updated_at BETWEEN  ? AND ?", params[:rating_id], params[:date], DateTime.now).order("updated_at desc").limit(30)
      if @comment.present?
        get_api_message "200", "Created"
        respond_to do |format|
          format.html { redirect_to @comment, notice: 'Comment was successfully found.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :comment => @comment.collect { |t| t.attributes.keep_if { |k, v| k != "user_id" }.merge!({user: t.user}) }}} }
        end
      else
        get_api_message "404", "no comment found for the given rating_id"
        respond_to do |format|
          format.html { redirect_to @comment, notice: 'not found.' }
          format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message}} }
        end
      end
    else
      get_api_message "501", "Invalid Request"
      respond_to do |format|
        format.html { redirect_to @comment, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status => @message.status, :code => @message.code, :message => @message.custom_message, :rating_id => params[:rating_id], :auth_token => params[:auth_token], :date => params[:date]}} }
      end
    end
  end
end
