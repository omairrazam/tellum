class Api::RatingsController < Api::ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_user!

  def create
    current_user = User.find_by_authentication_token params[:auth_token]
    @rating = Rating.new params[:request][:rating].merge!({ user_id: current_user.id })
    #tellum_host = request.host
    tag = Tag.find(params[:request][:rating][:tag_id])
    tag_creator_user_id = tag.try(:user)
    @user = current_user
    anonymous_rating = params[:request][:rating][:is_anonymous_rating]
    if @rating.save
      # commented mail section
      # unless tag_creator_user_id.id == current_user.id
      #  SendMailToTagCreator.send_tag_creator(current_user, tag_creator_user_id.id, params[:request][:rating][:tag_id], anonymous_rating, tellum_host).deliver if tag_creator_user_id.email.present?
      # end
      badge_count = tag_creator_user_id.try(:badge_count) + 1
      tag_creator_user_id.update_attributes badge_count: badge_count
      if @rating.is_anonymous_rating == true
        APNS.send_notification(tag_creator_user_id.try(:device_token), alert: "Anonymous dropped on #{tag.try(:tag_line)}",badge: badge_count, sound: "default" )
      else
        APNS.send_notification(tag_creator_user_id.try(:device_token), alert: "#{current_user.try(:full_name)} dropped on #{tag.try(:tag_line)}",badge: badge_count, sound: "default" )
      end
      Notification.create(user_id: tag.user_id, rating_id: @rating.id, object_name: "Rating", sender_id: current_user.id) if current_user.id != tag_creator_user_id.id
      get_api_message "200","Created"
      respond_to do |format|
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :rating => @rating.attributes.keep_if { |k, v| k.to_s != "tag_id"  }.keep_if { |k, v| k.to_s != "user_id"  }.merge!({ tag_line: Tag.find(@rating.tag_id).attributes ,user: User.find(@rating.user_id).hide_fields })  } } }
      end
    else
      unless @rating.errors.empty?
        get_api_message "501","Invalid Request"
        @errors=get_model_error(@rating)
        return render_errors
      end
      get_api_message "404","Record could not be created"
      return render_response
    end
  end
  def like_rating
    if params[:request][:rating][:rating_id]
      current_user = User.find_by_authentication_token params[:auth_token]
      @user_rating = UserRating.where(rating_id: params[:request][:rating][:rating_id], user_id: current_user.id).last
      @rating = Rating.find params[:request][:rating][:rating_id]
      if @user_rating.present?
        @user_rating.update_attributes(is_like: params[:request][:rating][:is_like])
        if params[:request][:rating][:is_like] == true
          # badge_count = @rating.try(:user).try(:badge_count) + 1
          # @rating.try(:user).update_attributes badge_count: badge_count
          @rating.update_attributes(rating_like_count: ((@rating.rating_like_count || 0) + 1))
          unless @rating.try(:user).try(:id) == current_user.id
            APNS.send_notification(@rating.try(:user).try(:device_token), alert: "#{current_user.try(:full_name)} liked #{@rating.try(:tag).try(:tag_line)}",badge: check_badge_count(@rating), sound: "default" )
            Notification.create(user_id: @rating.try(:user).try(:id), rating_id: @rating.id, object_name: "like rating", sender_id: current_user.id)
          end
        else
          @rating.update_attributes(rating_like_count: ((@rating.rating_like_count || 0) - 1))
        end
        get_api_message "200","updated rating"
        respond_to do |format|
          format.html { redirect_to @rating, notice: 'Rating was updated successfully.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message } }  }
        end
      else
        @user_rating = UserRating.new user_id: current_user.id, rating_id: params[:request][:rating][:rating_id], is_like: params[:request][:rating][:is_like]
        if params[:request][:rating][:is_like] == true
          @rating.update_attribute :rating_like_count, ((@rating.rating_like_count || 0) + 1)
          unless @rating.try(:user).try(:id) == current_user.id
            APNS.send_notification(@rating.try(:user).try(:device_token), alert: "#{current_user.try(:full_name)} liked #{@rating.try(:tag).try(:tag_line)}",badge: check_badge_count(@rating), sound: "default" )
            Notification.create(user_id: @rating.try(:user).try(:id), rating_id: @rating.id, object_name: "like rating", sender_id: current_user.id)
          end
        else
          @rating.update_attributes(rating_like_count: ((@rating.rating_like_count || 0) - 1)) unless @rating.rating_like_count == 0
        end
        if @user_rating.save
          get_api_message "200","Created"
          respond_to do |format|
            format.html { redirect_to @user_rating, notice: 'UserRating was successfully created.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message} } }
          end
        else
          unless @user_rating.errors.empty?
            get_api_message "501","Invalid Request"
            @errors=get_model_error(@user_rating)
            return render_errors
          end
          get_api_message "404","Record could not be created"
          return render_response
        end
      end
    else
      get_api_message "501","Invalid Request"
      @errors=get_model_error(@rating || @user_rating)
      return render_errors
    end
  end
  def likes_list
    if params[:auth_token] && params[:rating_id]
      current_user = User.find_by_authentication_token params[:auth_token]
      @user_rating = UserRating.where(rating_id: params[:rating_id], is_like: true)
      if !@user_rating.empty?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @user_rating }
          format.json { render json: {:response => {:status => @message.status,:code => @message.code,:message => @message.custom_message, :likes => @user_rating.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ user: check_user(t.user, current_user)})} } }  }
        end
      else
        get_api_message "404","not found"
        respond_to do |format|
          format.html { redirect_to @user_rating }
          format.json { render json: {:response => {:status => @message.status,:code => @message.code,:message => @message.custom_message } }  }
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to params, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message => @message.custom_message, :params => { auth_token: params[:auth_token], rating_id: params[:rating_id] } }  } }
      end
    end
  end
  def ratings_of_a_tag
    if params[:tag_id].present? &&  params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token params[:auth_token]
      #@rating = Rating.select("*, ( (select count(*) from comments where comments.rating_id = ratings.id) + ( select count(*) from user_ratings where user_ratings.rating_id = ratings.id and is_like =`1`)) AS ratings_comment_counts").where("ratings.tag_id = ? AND ratings.updated_at < ?", params[:tag_id], params[:date]).order("ratings_comment_counts DESC")
      @rating = Rating.select("*, ( (select count(*) from comments where comments.rating_id = ratings.id) + ( select count(*) from user_ratings where user_ratings.rating_id = ratings.id and user_ratings.is_like ='1')) AS ratings_comment_counts").where("ratings.tag_id = ? AND ratings.updated_at < ?", params[:tag_id], params[:date]).order("created_at DESC").limit(30)
      if @rating.present?
        get_api_message "200","Created"
        respond_to do |format|
          format.html { redirect_to @rating, notice: 'rating was successfully found.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :rating => @rating.collect { |t| t.attributes.keep_if { |k, v| !["user_id", "tag_id"].include?(k)  }.merge!({comments: t.comments.count, is_like: UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false,   user: t.user.hide_fields, tag_line: Tag.find(t.tag_id).attributes.keep_if{ |k, v|  !["user_id", "rating_id"].include?(k) }.merge!({user: Tag.find(t.tag_id).user.hide_fields,   average_rating: Tag.find(t.tag_id).average_rating, total_rating: Tag.find(t.tag_id).total_rating })   } )   } } } }
        end
      else
        get_api_message "404","no rating found for the given rating_id"
        respond_to do |format|
          format.html { redirect_to @rating, notice: 'not found.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message} } }
        end
      end
    else
      if params[:tag_id].present? &&  params[:auth_token].present?
        current_user = User.find_by_authentication_token params[:auth_token]
        #@rating = Rating.where(tag_id:  params[:tag_id])
        @rating = Rating.select("*, ( (select count(*) from comments where comments.rating_id = ratings.id) + ( select count(*) from user_ratings where user_ratings.rating_id = ratings.id and is_like ='1')) AS ratings_comment_counts").where("ratings.tag_id = ?", params[:tag_id]).order("created_at DESC").limit(30)
        if @rating.present?
          get_api_message "200","Created"
          respond_to do |format|
            format.html { redirect_to @rating, notice: 'rating was successfully found.' }
            #format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :rating => @rating.collect { |t| t.attributes.keep_if { |k, v| k != "user_id"  }.merge!({ user: t.user })   } } } }
            #format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :rating => @rating.collect { |t| t.attributes.keep_if { |k, v| !["user_id", "tag_id"].include?(k)  }.merge!({ user: t.user, tag_line: Tag.find(t.tag_id).attributes.keep_if{ |k, v|  !["user_id", "rating_id"].include?(k) }.merge!({user: Tag.find(t.tag_id).user})   } )   } } } }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :rating => @rating.collect { |t| t.attributes.keep_if { |k, v| !["user_id", "tag_id"].include?(k)  }.merge!({comments: t.comments.count, is_like: UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false,   user: t.user.hide_fields, tag_line: Tag.find(t.tag_id).attributes.keep_if{ |k, v|  !["user_id", "rating_id"].include?(k) }.merge!({ user: Tag.find(t.tag_id).user.hide_fields, average_rating: Tag.find(t.tag_id).average_rating, total_rating: Tag.find(t.tag_id).total_rating })   } )   } } } }
          end
        else
          get_api_message "404","no rating found for the given rating_id"
          respond_to do |format|
            format.html { redirect_to @rating, notice: 'not found.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message} } }
          end
        end
      else
        get_api_message "501","Invalid Request"
        respond_to do |format|
          format.html { redirect_to @rating, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag_id => params[:tag_id], :auth_token => params[:auth_token] } } }
        end
      end
    end
  end
  def ratings_of_a_tag_PTR
    if params[:tag_id].present? &&  params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token params[:auth_token]
      @rating = Rating.select("*, ( (select count(*) from comments where comments.rating_id = ratings.id) + ( select count(*) from user_ratings where user_ratings.rating_id = ratings.id and is_like ='1')) AS ratings_comment_counts").where("tag_id = ? AND updated_at BETWEEN  ? AND ?", params[:tag_id], params[:date], DateTime.now).order("created_at DESC")
      if @rating.present?
        get_api_message "200","Created"
        respond_to do |format|
          format.html { redirect_to @rating, notice: 'Rating found.' }
          #format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :rating => @rating.collect { |t| t.attributes.keep_if { |k, v| k != "user_id"  }.merge!({ user: t.user })   } } } }
          #format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :rating => @rating.collect { |t| t.attributes.keep_if { |k, v| !["user_id", "tag_id"].include?(k)  }.merge!({ user: t.user, tag_line: Tag.find(t.tag_id).attributes.keep_if{ |k, v|  !["user_id", "rating_id"].include?(k) }.merge!({user: Tag.find(t.tag_id).user})   } )   } } } }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :rating => @rating.collect { |t| t.attributes.keep_if { |k, v| !["user_id", "tag_id"].include?(k)  }.merge!({ comments: t.comments.count, is_like: UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false, user: t.user, tag_line: Tag.find(t.tag_id).attributes.keep_if{ |k, v|  !["user_id", "rating_id"].include?(k) }.merge!({ user: Tag.find(t.tag_id).user, average_rating: Tag.find(t.tag_id).average_rating, total_rating: Tag.find(t.tag_id).total_rating })   } )   } } } }
        end
      else
        get_api_message "404","no rating found for the given tag_id"
        respond_to do |format|
          format.html { redirect_to @rating, notice: 'not found.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message} } }
        end
      end
    else
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @rating, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag_id => params[:tag_id], :auth_token => params[:auth_token], :date => params[:date] } } }
      end
    end
  end
  def check_flag
    if params[:auth_token].present? && params[:request][:drop_id].present?
      user = User.find_by_authentication_token params[:auth_token]
      @rating = Rating.find(params[:request][:drop_id])
      flagged_dop = FlaggedDrop.where user_id: user.id, rating_id:  @rating.id
      if flagged_dop.blank?
        FlaggedDrop.create user_id: user.id, rating_id: @rating.id, is_flagged: true
        @rating.update_attribute :is_flagged, true
        if @rating.present?
          get_api_message "200","success"
          respond_to do |format|
            format.html { redirect_to @rating, notice: 'Flagged this content.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :rating => @rating.attributes.merge({user: @rating.user}) } } }
          end
        else
          get_api_message "404","no tag found"
          respond_to do |format|
            format.html { redirect_to @rating, notice: 'not found' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
          end
        end
      else
        get_api_message "501","You already flagged the same Drop"
        respond_to do |format|
          format.html { redirect_to @rating, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @rating, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message  }}}
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
  def check_badge_count rating
    badge_count = rating.try(:user).try(:badge_count) + 1
    rating.try(:user).update_attributes badge_count: badge_count
    badge_count
  end
end
