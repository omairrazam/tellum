class Api::TagsController < Api::ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_user!

  def create
    @tag = Tag.new(params[:request][:tag_line])
    if @tag.save
      @tag.open_date = @tag.open_date.utc
      @tag.close_date = @tag.close_date.utc
      get_api_message "200","Created"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Tag was successfully created.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag, :user => current_user }   }}
      end
    else
      unless @tag.errors.empty?
        get_api_message "501","Invalid Request"
        @errors=get_model_error(@tag)
        return render_errors
      end
      get_api_message "404","Tag could not be created"
      return render_response
    end
  end
  def get_all_taglines
    @user = User.find_by_authentication_token params[:auth_token]
    @tags = get_all_tags if @user.present?
  end
  def check_tag_expiry
    if params[:auth_token] && params[:tag_id]
      @tag = Tag.find(params[:tag_id])
      @expiry_time = check_expiry(@tag)
    else
      @invalid_request = "Invalid"
    end
  end
  def tag_detail
    if params[:auth_token] && params[:tag_id]
      current_user = User.find_by_authentication_token(params[:auth_token])
      @tag = Tag.find_by_id(params[:tag_id])
      #@tag = check_follower(tag, current_user)
      if @tag
        @tag.open_date = @tag.open_date.utc
        @tag.close_date = @tag.close_date.utc
        get_api_message "200","ok"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'Tag was successfully found.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag.attributes.keep_if { |k, v| k != "user_id"  }.merge!({:total_rating=> @tag.total_rating, :average_rating => @tag.average_rating, user: check_follower(@tag, current_user).user})}  } }
        end
      else
        get_api_message "404","not found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags => @tags } } }
        end
      end
    else
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag_id => params[:tag_id], :auth_token => params[:auth_token] } } }
      end
    end
  end
  def get_box_description
    @box_detail = Tag.find_by_id(params[:tag_id]) if params[:auth_token].present?
  end
  def get_total_drops
    @total_drops = Tag.find_by_id(params[:tag_id]).try(:ratings).try(:count) if params[:auth_token].present? && params[:tag_id]
  end
  def get_top_boxes
    user = User.find_by_authentication_token params[:auth_token]
    @total_drops =
        Tag.find_by_id(params[:tag_id]).try(:ratings).try(:count) if params[:auth_token].present? && params[:tag_id]
  end
  def tag_line_including_locked
    if params[:auth_token].nil?
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :search_term => params[:search_term], :auth_token => params[:auth_token] } } }
      end
    else
      if params[:search_term].nil?
        @tag = Tag.where("(close_date > ? AND close_date IS NOT NULL) OR (created_at >= NOW() - INTERVAL 10 MINUTE)", DateTime.now)
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'success.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag_lines => @tag } } }
        end
      else
        @tag = Tag.where("tag_line = ? AND DATE(close_date) < ?  AND ( close_date IS NOT NULL OR updated_at >= NOW() - INTERVAL 10 MINUTE)", params[:search_term], DateTime.now.to_date)
        unless @tag.empty?
          if !@tag.close_date.nil? && !@tag.open_date.nil?
            @tag.collect! { |t| t.close_date, t.open_date = t.close_date.utc, t.open_date.utc; t }
          end
          get_api_message "200","success"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'success.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag_lines => @tag } } }
          end
        else
          get_api_message "404","no tag found"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'not found.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message} } }
          end
        end
      end
    end
  end
  def search_tagline_exectmatch
    if params[:auth_token].nil? && params[:tag_line].nil?
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :search_term => params[:search_term], :auth_token => params[:auth_token] } } }
      end
    else
      @tag = Tag.where("tag_line = ?", CGI::unescape(params[:tag_line]))
      unless @tag.empty?
        @tag.collect do |tag|
          unless tag.close_date.nil? && tag.open_date.nil?
            tag.close_date, tag.open_date = tag.close_date.utc, tag.open_date.utc; tag
          end
        end.reject!(&:blank?)
        #rating = find_rating(@tag)
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'success.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code, :message=>@message.custom_message, :open_tag_count => @tag.where("is_locked = ? AND close_date > ? " , true, DateTime.now.to_datetime.utc.to_s(:db)).count, :close_tag_count => @tag.where("close_date <= ? " , DateTime.now.to_datetime.utc.to_s(:db)).count, :open_tag_lines => @tag.where("is_locked = ? AND close_date > ? " , true, DateTime.now.to_datetime.utc.to_s(:db)).collect { |t| t.attributes.keep_if { |k, v| k != "user_id"  }.merge!( {:total_rating=> t.total_rating, :average_rating => t.average_rating }).merge!({ user: t.user })   }, :close_tag_lines => @tag.where("close_date <= ? " , DateTime.now.to_datetime.utc.to_s(:db)).collect { |t| t.attributes.keep_if { |k, v| k != "user_id"  }.merge!( {:total_rating=> t.total_rating, :average_rating => t.average_rating }).merge!({ user: t.user })   }   } } }
        end
      else
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}, :open_tag_count => @tag.where(is_locked: false).count, :close_tag_count => @tag.where(is_locked: true).count, :open_tag_lines => @tag.where(is_locked: false), :close_tag_lines => @tag.where(is_locked: true) } }
        end
      end
    end
  end
  def search_tagline_exectmatch_with_status
    @tag = Tag.where("tag_line = ?", CGI::unescape(params[:tag_line])) if params[:tag_line].present?
    @tag_line = params[:tag_line]
  end
  def search_tagline_title_contains
    if params[:auth_token].nil? && params[:tag_line].nil?
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :search_term => params[:search_term], :auth_token => params[:auth_token] } } }
      end
    else
      @tag = Tag.where("tag_line like :query", { query: "%#{params[:tag_line]}%" })
      unless @tag.empty?
        @tag.collect do |tag|
          unless tag.close_date.nil? && tag.open_date.nil?
            tag.close_date, tag.open_date = tag.close_date.utc, tag.open_date.utc; tag
          end
        end.reject!(&:blank?)
        #rating = find_rating(@tag)
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'success.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code, :message=>@message.custom_message, :open_tag_count => @tag.where("is_locked = ? AND close_date > ? " , true, DateTime.now.to_datetime.utc.to_s(:db)).count, :close_tag_count => @tag.where("close_date <= ? " , DateTime.now.to_datetime.utc.to_s(:db)).count, :open_tag_lines => @tag.where("is_locked = ? AND close_date > ? " , true, DateTime.now.to_datetime.utc.to_s(:db)).collect { |t| t.attributes.keep_if { |k, v| k != "user_id"  }.merge!( {:total_rating=> t.total_rating, :average_rating => t.average_rating }).merge!({ user: t.user })   }, :close_tag_lines => @tag.where("close_date <= ? " , DateTime.now.to_datetime.utc.to_s(:db)).collect { |t| t.attributes.keep_if { |k, v| k != "user_id"  }.merge!( {:total_rating=> t.total_rating, :average_rating => t.average_rating }).merge!({ user: t.user })   }   } } }
        end
      else
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code, :message=>@message.custom_message, :open_tag_count => Tag.where("is_locked = ? AND close_date > ?" , true, Date.today).count, :close_tag_count => Tag.where("close_date <= ?" , Date.today).count, :open_tag_lines => Tag.where("is_locked = ? AND close_date > ?" , true, Date.today).collect { |t| t.attributes.keep_if { |k, v| k != "user_id"  }.merge!( (rating[:rating][:total_rating].present? && rating[:rating][:average_rating].present?) ?  {:total_rating=> find_rating(@tag)[:rating][:total_rating], :average_rating => find_rating(@tag)[:rating][:average_rating] } : {} ).merge!({ user: t.user })   }, :close_tag_lines => Tag.where("close_date <= ?" , Date.today).collect { |t| t.attributes.keep_if { |k, v| k != "user_id"  }.merge!( (rating[:rating][:total_rating].present? && rating[:rating][:average_rating].present?) ?  {:total_rating=> find_rating(@tag)[:rating][:total_rating], :average_rating => find_rating(@tag)[:rating][:average_rating] } : {} ).merge!({ user: t.user })   }   } } }
        end
      end
    end
  end
  def box_time_line
    @user = User.find_by_authentication_token params[:auth_token]
  end
  def explore_tab
    @user = User.find_by_authentication_token params[:auth_token]
  end
  def search_tagline_any_where
    if params[:auth_token].nil? && params[:tag_line].nil?
      get_api_message "501","Invalid Request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message } } }
      end
    else
      current_user = User.find_by_authentication_token(params[:auth_token])
      @tag = Tag.where("tag_line like :query OR tag_title LIKE :query OR tag_description like :query",{ query: "%#{params[:tag_line]}%" })
      @tags = @tag.where("close_date is not NULL AND close_date >= ?", DateTime.now)
      if @tags.present?
        # @tag.collect do |tag|
        #   unless tag.close_date.nil? && tag.open_date.nil?
        #     tag.close_date, tag.open_date = tag.close_date.utc, tag.open_date.utc; tag
        #   end
        # end.reject!(&:blank?)
        #rating = find_rating(@tag)
        debugger
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'success.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code, :message=>@message.custom_message, :boxes => current_user.box_story_hash_structure(@tags)} } }
        end
      else
        get_api_message "200"," Not found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message } } }
          #format.json { render json: {:response => {:status=>@message.status,:code=>@message.code, :message=>@message.custom_message, :open_tag_count => @tag.where("is_locked = ? AND close_date > ?" , true, Date.today.to_time.utc).count, :close_tag_count => @tag.where("close_date <= ?" , Date.today.to_time.utc).count, :open_tag_lines => @tag.where("is_locked = ? AND close_date > ?" , true, Date.today.to_time.utc).collect { |t| t.attributes.keep_if { |k, v| k != "user_id"  }.merge!( (rating[:rating][:total_rating].present? && rating[:rating][:average_rating].present?) ?  {:total_rating=> find_rating(@tag)[:rating][:total_rating], :average_rating => find_rating(@tag)[:rating][:average_rating] } : {} ).merge!({ user: t.user })   }, :close_tag_lines => @tag.where("close_date <= ?" , Date.today.to_time.utc).collect { |t| t.attributes.keep_if { |k, v| k != "user_id"  }.merge!( (rating[:rating][:total_rating].present? && rating[:rating][:average_rating].present?) ?  {:total_rating=> find_rating(@tag)[:rating][:total_rating], :average_rating => find_rating(@tag)[:rating][:average_rating] } : {} ).merge!({ user: t.user })   }   } } }
        end
      end
    end
  end
  def lock_tag
    current_user = User.find_by_authentication_token(params[:auth_token])
    @tag_line = Tag.where(tag_line: params[:request][:tag_line][:tag_line]).last
    unless @tag_line.nil?
      if @tag_line.user_id != current_user
        tag_line = Tag.where(tag_line: params[:request][:tag_line][:tag_line], user_id: current_user).last
        if tag_line.present?
          @tag_line = tag_line
        end
      end
      if @tag_line.close_date
        if @tag_line.is_locked == true
          if Date.today.to_time.utc >= @tag_line.close_date.to_time.utc
            if @tag_line.user_id == current_user.id
              @tag_line.update_attributes(tag_line: params[:request][:tag_line][:tag_line], is_locked: true, user_id: current_user.id, updated_time: Time.now)
              get_api_message "200","Tag renewed"
              respond_to do |format|
                format.html { redirect_to @tag_line, notice: 'Tag line successfully renewed.' }
                format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag_line }}}
              end
            else
              @tag = Tag.new(tag_line: params[:request][:tag_line][:tag_line], is_locked: true, user_id: current_user.id, updated_time: Time.now)
              if @tag.save
                get_api_message "200","Tag created"
                respond_to do |format|
                  format.html { redirect_to @tag, notice: 'Tag line successfully assigned.' }
                  format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag }}}
                end
              else
                get_api_message "501","Invalid request"
                respond_to do |format|
                  format.html { redirect_to @tag, notice: 'Invalid request.' }
                  format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag }}}
                end
              end
            end
          else
            get_api_message "404","Tag alreday in used please wait #{((@tag_line.close_date.utc - Date.today.to_time.utc)/60).to_i} minutes to use this tag."
            respond_to do |format|
              format.html { redirect_to @tag, notice: 'Tag already in use.' }
              format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message }   }}
            end
          end
        else
          @tag = Tag.new(tag_line: params[:request][:tag_line][:tag_line], is_locked: true, user_id: current_user.id, updated_time: Time.now)
          if @tag.save
            get_api_message "200","Tag created"
            respond_to do |format|
              format.html { redirect_to @tag, notice: 'Tag line successfully assigned.' }
              format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag }}}
            end
          else
            get_api_message "501","Invalid request"
            respond_to do |format|
              format.html { redirect_to @tag, notice: 'Invalid request.' }
              format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag }}}
            end
          end
        end
      else
        created_time =  ((Time.now.utc - @tag_line.updated_time.utc)/60).to_i
        if created_time >= 10
          @tag = Tag.new(tag_line: params[:request][:tag_line][:tag_line], is_locked: true, user_id: current_user.id, updated_time: Time.now)
          if @tag.save
            get_api_message "200","Tag created"
            respond_to do |format|
              format.html { redirect_to @tag, notice: 'Tag line successfully assigned.' }
              format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag }}}
            end
          else
            get_api_message "501","Invalid request"
            respond_to do |format|
              format.html { redirect_to @tag, notice: 'Invalid request.' }
              format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag }}}
            end
          end
        else
          get_api_message "501","Tag already in use please wait #{10 - created_time} minutes."
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'Invalid request.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag_line }}}
          end
        end
      end
    else
      @tag = Tag.new(tag_line: params[:request][:tag_line][:tag_line], is_locked: true, user_id: current_user.id, updated_time: Time.now)
      if @tag.save
        get_api_message "200","Tag created"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'Tag line successfully assigned.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag }}}
        end
      else
        get_api_message "501","Invalid request"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag }}}
        end
      end
    end
  end
  def update_tag_info
    @tag = Tag.find(params[:request][:tag_line][:box_id])
    if params[:request][:tag_line][:tag_line] == @tag.tag_line
      @tag.update_attributes params[:request][:tag_line].except!(:box_id)
      get_api_message "200","Tag updated"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Tag successfully updated.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag }}}
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag }}}
      end
    end
  end
  def taglines_and_ratings_by_followings
    if params[:auth_token].present? && params[:date].present?
      #@rating = current_user.ratings.where("is_post_to_wall = ? AND updated_at < ?", true, params[:date]).order("updated_at desc")
      @user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("is_anonymous_rating = ? AND is_post_to_wall = ? AND created_at < ? AND user_id IN (?)", false, true, params[:date], UserFollow.where("follow_id = ? AND is_approved = ?", current_user.id, true).pluck(:user_id).uniq).order("created_at desc")
      @tag = Tag.where("close_date is NOT NULL AND is_post_to_wall = ? AND updated_at < ? AND user_id IN (?)", true, params[:date], UserFollow.where("follow_id = ? AND is_approved = ?", current_user.id, true).pluck(:user_id).uniq)
      @tag = check_followers(@tag, @user) if @tag.present?
      @tags_and_ratings = tag_and_ratings @tag, @rating
      if @tags_and_ratings.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }.first(30) } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      if params[:auth_token].present?
        current_user = User.find_by_authentication_token(params[:auth_token])
        #users = UserFollow.where(follow_id: User.find_by_authentication_token(params[:auth_token]).id)
        @rating =  Rating.where("is_anonymous_rating = ? AND is_post_to_wall = ? AND user_id IN (?)", false, true, UserFollow.where("follow_id = ? AND is_approved = ?", current_user.id, true).pluck(:user_id).uniq).order("created_at desc")
        @tag = Tag.where("close_date is NOT NULL AND is_post_to_wall = ? AND user_id IN (?)", true, UserFollow.where("follow_id = ? AND is_approved = ?", current_user.id, true).pluck(:user_id).uniq)
        @tag = check_followers(@tag, current_user) if @tag.present?
        @tags_and_ratings = tag_and_ratings @tag, @rating
        if @tags_and_ratings.present?
          get_api_message "200","success"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort! { |a, b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }.first(30) } } }
          end
        else
          get_api_message "404","no tag found"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'not found' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
          end
        end
      else
        get_api_message "501","Invalid request"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token] }}}
        end
      end
    end
  end
  def taglines_and_ratings_by_followings_and_me
    if params[:auth_token].present? && params[:date].present?
      #@rating = current_user.ratings.where("is_post_to_wall = ? AND updated_at < ?", true, params[:date]).order("updated_at desc")
      @user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("is_anonymous_rating = ? AND is_post_to_wall = ? AND created_at < ? AND user_id IN (?)", false, true, params[:date], UserFollow.where("follow_id = ? AND is_approved = ?", current_user.id, true).pluck(:user_id).uniq) + @user.ratings.where("created_at < ?", params[:date])
      @tag = Tag.where("close_date is NOT NULL AND is_post_to_wall = ? AND created_at < ? AND user_id IN (?)", true, params[:date], UserFollow.where("follow_id = ? AND is_approved = ?", current_user.id, true).pluck(:user_id).uniq) + @user.tags.where("close_date is NOT NULL AND created_at < ?", params[:date])
      @tag = check_followers(@tag, @user) if @tag.present?
      @tags_and_ratings = tag_and_ratings @tag, @rating
      if @tags_and_ratings.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }.first(30) } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      if params[:auth_token].present?
        current_user = User.find_by_authentication_token(params[:auth_token])
        #users = UserFollow.where(follow_id: User.find_by_authentication_token(params[:auth_token]).id)
        @rating =  Rating.where("is_anonymous_rating = ? AND is_post_to_wall = ? AND user_id IN (?)", false, true, UserFollow.where("follow_id = ? AND is_approved = ?", current_user.id, true).pluck(:user_id)) + current_user.ratings
        @tag = Tag.where("close_date is NOT NULL AND is_post_to_wall = ? AND user_id IN (?)", true, UserFollow.where("follow_id = ? AND is_approved = ?", current_user.id, true).pluck(:user_id).uniq) + current_user.tags.where("close_date is NOT NULL")
        @tag = check_followers(@tag, current_user) if @tag.present?
        @tags_and_ratings = tag_and_ratings @tag, @rating
        if @tags_and_ratings.present?
          get_api_message "200","success"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort! { |a, b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }.first(30) } } }
          end
        else
          get_api_message "404","no tag found"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'not found' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
          end
        end
      else
        get_api_message "501","Invalid request"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token] }}}
        end
      end
    end
  end
  def tagslines_by_followings
    if params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @tag = Tag.where("updated_at < ?", params[:date].to_datetime.to_s(:db)).order("updated_at desc").limit(30)
      if @tag.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :response =>   @tag.map{ |t| t.find_is_tag_line(current_user)  } } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token], :date => params[:date] }}}
      end
    end
  end
  def ratings_by_followings
    if params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @tag = Tag.where(updated_at: params[:date].to_datetime.to_s(:db)).order("updated_at desc").limit(30)
      if @tag.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :response =>   @tag.map{ |t| t.find_is_tag_line(current_user)  } } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token], :date => params[:date] }}}
      end
    end
  end
  def tagslines_by_followings_PTR
    if params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @tag = Tag.where("updated_at <= ?", params[:date].to_datetime.to_s(:db)).order("updated_at desc")
      if @tag.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :response =>   @tag.map{ |t| t.find_is_tag_line(current_user)  } } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token], :date => params[:date] }}}
      end
    end
  end
  def ratings_by_followings_PTR
    if params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @tag = Tag.where("updated_at <= ?", params[:date].to_datetime.to_s(:db)).order("updated_at desc")
      if @tag.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :response =>   @tag.map{ |t| t.find_is_tag_line(current_user)  } } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token], :date => params[:date] }}}
      end
    end
  end
  def tagslines_most_popular_PTR
    if params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @tag = Tag.where("updated_at <= ?", params[:date].to_datetime.to_s(:db)).order("updated_at desc")
      if @tag.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :response =>   @tag.map{ |t| t.find_is_tag_line(current_user)  } } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token], :date => params[:date] }}}
      end
    end
  end
  def ratings_most_popular_PTR
    if params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @tag = Tag.where("updated_at <= ?", params[:date].to_datetime.to_s(:db)).order("updated_at desc")
      if @tag.present?
        @tag = @tag.map do |t|
          if t.id == UserFollow.find_by_user_id(current_user.id)
            t.update_attributes is_following: true
          end
          if t.id == UserFollow.find_by_follow_id(current_user.id)
            t.update_attributes is_follower: true
          end
          t
        end
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :response =>   @tag.map{ |t| t.find_is_tag_line(current_user)  } } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token], :date => params[:date] }}}
      end
    end
  end
  def taglines_and_ratings_most_popular_PTR
    if params[:auth_token].present? && params[:date].present?
      #@tag = Tag.where("updated_at BETWEEN  ? AND ?", params[:date], DateTime.now).order("updated_at desc").limit(30)
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("updated_at BETWEEN  ? AND ?", params[:date], DateTime.now).order("rating_like_count DESC")
      @tag = Tag.select("*, (SELECT COUNT(*) FROM ratings WHERE ratings.tag_id = tags.id ) AS tags_ratings_total_count").where("close_date is NOT NULL AND close_date  >= ? AND updated_at BETWEEN  ? AND ?", DateTime.now, params[:date], DateTime.now).order("tags_ratings_total_count DESC")
      @tag = check_followers(@tag, current_user) if @tag.present?
      #@tags_and_ratings = (@tag.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!(average_rating: t.average_rating, total_rating: t.total_rating, user: t.user)} + @rating.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!( tag_line: Tag.find_by_id(t.tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ user: Tag.find_by_id(t.tag_id).user }), comments: t.comments.count, user: t.user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false ) )  }).sort do |a, b|
      #  inner_a =  inner_b = String.newa
      #  if a["tag_id"]
      ##    inner_a = ( Tag.find_by_id(a["tag_id"]).total_rating + Tag.find_by_id(a["tag_id"]).ratings.map(&:rating_like_count).map(&:to_f).sum + Tag.find_by_id(a["tag_id"]).ratings.map(&:comments).count )
      #  else
      #    inner_a = ( Tag.find_by_id(a["id"]).total_rating + Tag.find_by_id(a["id"]).ratings.map(&:rating_like_count).map(&:to_f).sum + + Tag.find_by_id(a["id"]).ratings.map(&:comments).count )
      #  end
      #  if b["tag_id"]
      #    inner_b = ( Tag.find_by_id(b["tag_id"]).total_rating + Tag.find_by_id(b["tag_id"]).ratings.map(&:rating_like_count).map(&:to_f).sum + Tag.find_by_id(b["tag_id"]).ratings.map(&:comments).count )
      #  else
      #    inner_b = ( Tag.find_by_id(b["id"]).total_rating + Tag.find_by_id(b["id"]).ratings.map(&:rating_like_count).map(&:to_f).sum + Tag.find_by_id(b["id"]).ratings.map(&:comments).count )
      #  end
      #  inner_b <=> inner_a
      #end.first(30)
      @tags_and_ratings = tags_and_ratings @tag, @rating
      if @tags_and_ratings.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:respontimetise => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort_by { |argonite| argonite[:fuck_the_fuckers]}.reverse } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token], :date => params[:date] }}}
      end
    end
  end
  def boxes_and_drops_created_by_me
    @user = User.find_by_authentication_token(params[:auth_token])
    @user_id = params[:user_id]
    if params[:user_id].present?
      @boxes = User.find(params[:user_id]).try(:tags).where("close_date is not NULL")
      @drops = User.find(params[:user_id]).try(:ratings).where("is_anonymous_rating = ? AND is_box_locked = ?", false, false)
    else
      @boxes = @user.try(:tags).where("close_date is not NULL")
      @drops = @user.try(:ratings)
    end
  end
  def tagslines_by_user
    if params[:auth_token].present? && params[:user_id].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @tag = Tag.where("is_post_to_wall = ? AND close_date is NOT NULL AND user_id = ?", true, params[:user_id])
      if @tag.present?
        @tag = check_followers(@tag, current_user)
        @tags = (@tag.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!(average_rating: t.average_rating, total_rating: t.total_rating, user: t.user)} ).sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }.first(30)
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags =>   @tags } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      if params[:auth_token].present?
        current_user = User.find_by_authentication_token(params[:auth_token])
        @tag = current_user.tags.where("close_date is not NULL")
        if @tag.present?
          #@tag = check_followers(@tag, current_user) if @tag.present?
          #@tags = (@tag.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!(average_rating: t.average_rating, total_rating: t.total_rating, user: t.user)}).sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }.first(30)
          get_api_message "200","success"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :boxes =>   current_user.box_story_hash_structure(@tag) } } }
          end
        else
          get_api_message "404","no tag found"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'not found' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
          end
        end
      else
        get_api_message "501","Invalid request"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token], :user_id => params[:user_id] }}}
        end
      end
    end
  end
  def taglines_and_ratings_by_user
    if params[:auth_token].present? && params[:user_id].present? && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("is_post_to_wall = ? AND user_id = ? AND is_anonymous_rating = ? AND created_at < ?", true, params[:user_id], false, params[:date]).order("created_at desc")
      @tag = Tag.where("is_post_to_wall = ? AND close_date is NOT NULL AND created_at < ? AND user_id = ?", true, params[:date], params[:user_id]).order("created_at desc")
      @tag = check_followers(@tag, current_user)
      @tags_and_ratings = tag_and_ratings @tag, @rating
      if @tags_and_ratings.present?
        egt_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }.first(30)  } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    elsif params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("user_id = ? AND created_at < ?", current_user.id, params[:date]).order("created_at desc")
      @tag = Tag.where("close_date is NOT NULL AND created_at < ? AND user_id = ?", params[:date], current_user.id).order("created_at desc")
      @tag = check_followers(@tag, current_user) if @tag.present?
      @tags_and_ratings = tag_and_ratings @tag, @rating
      if @tags_and_ratings.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }.first(30)  } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    elsif params[:auth_token].present? && params[:user_id].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("is_post_to_wall = ? AND user_id = ? AND is_anonymous_rating = ?", true, params[:user_id], false).order("created_at desc")
      @tag = Tag.where("is_post_to_wall = ? AND close_date is NOT NULL AND user_id = ?", true, params[:user_id]).order("created_at desc")
      @tag = check_followers(@tag, current_user) if @tag.present?
      @tags_and_ratings = tag_and_ratings @tag, @rating
      if @tags_and_ratings.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }.first(30)  } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      if params[:auth_token].present?
        current_user = User.find_by_authentication_token(params[:auth_token])
        @rating = Rating.where(user_id: current_user.id).order("created_at desc")
        @tag = Tag.where("close_date is NOT NULL AND  user_id = ?", current_user.id).order("created_at desc")
        #@tag = check_followers(@tag, current_user)
        @tags_and_ratings = current_user.box_story_hash_structure(@tag) + current_user.drop_story_hash_structure(@rating)
        if @tags_and_ratings.present?
          get_api_message "200","success"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :boxes_and_drops =>   @tags_and_ratings  } } }
          end
        else
          get_api_message "404","no tag found"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'not found' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
          end
        end
      else
        get_api_message "501","Invalid request"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token], :user_id => params[:user_id] }}}
        end
      end
    end
  end
  def ratings_by_user
    if params[:auth_token].present? && params[:user_id] && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("is_post_to_wall = ? AND user_id = ? AND is_anonymous_rating = ? AND created_at < ?", true, params[:user_id], false, params[:date]).order("created_at desc")
      if @rating.present?
        @rating = @rating.collect { |t| t.attributes.keep_if { |k, v| !["tag_id", "user_id"].include?(k)  }.merge!(tag_line: Tag.find_by_id(t.tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(t.tag_id).average_rating, total_rating: Tag.find_by_id(t.tag_id).total_rating, user: check_user(Tag.find_by_id(t.tag_id).user, current_user) }), comments: t.comments.count, user: t.user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false )  )}.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }.first(30)
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :ratings =>   @rating } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    elsif params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("is_post_to_wall = ? AND user_id = ? AND is_anonymous_rating = ? AND created_at < ?", true, current_user, false, params[:date]).order("created_at desc")
      if @rating.present?
        @rating = @rating.collect { |t| t.attributes.keep_if { |k, v| !["tag_id", "user_id"].include?(k)  }.merge!(tag_line: Tag.find_by_id(t.tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(t.tag_id).average_rating, total_rating: Tag.find_by_id(t.tag_id).total_rating, user: check_user(Tag.find_by_id(t.tag_id).user, current_user) }), comments: t.comments.count, user: t.user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false )  )}.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }.first(30)
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :ratings =>   @rating } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    elsif params[:auth_token].present? && params[:user_id]
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("is_post_to_wall = ? AND user_id = ? AND is_anonymous_rating = ?", true, params[:user_id], false)
      if @rating.present?
        @rating = @rating.collect { |t| t.attributes.keep_if { |k, v| !["tag_id", "user_id"].include?(k)  }.merge!(tag_line: Tag.find_by_id(t.tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(t.tag_id).average_rating, total_rating: Tag.find_by_id(t.tag_id).total_rating, user: check_user(Tag.find_by_id(t.tag_id).user, current_user) }), comments: t.comments.count, user: t.user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false )  )}.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }.first(30)
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :ratings =>   @rating } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      if params[:auth_token].present?
        current_user = User.find_by_authentication_token(params[:auth_token])
        @rating = Rating.where("user_id = ?", current_user.id,)
        if @rating.present?
          #@rating = @rating.collect { |t| t.try(:attributes).keep_if { |k, v| !["tag_id", "user_id"].include?(k)  }.merge!(tag_line: Tag.find_by_id(t.tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(t.tag_id).average_rating, total_rating: Tag.find_by_id(t.tag_id).total_rating, user: check_user(Tag.find_by_id(t.tag_id).user, current_user) }), comments: t.comments.count, user: t.user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false )  )}.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }.first(30)
          get_api_message "200","success"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :drops =>   current_user.drop_story_hash_structure(@rating) } } }
          end
        else
          get_api_message "404","no tag found"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'not found' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
          end
        end
      else
        get_api_message "501","Invalid request"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token] }}}
        end
      end
    end
  end
  def tagslines_by_user_PTR
    if params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @tag = Tag.where("is_post_to_wall = ? AND close_date is NOT NULL AND user_id = ? AND created_at BETWEEN  ? AND ?", true, current_user.id, params[:date], DateTime.now )
      if @tag.present?
        @tag = check_followers(@tag, current_user)
        @tags = (@tag.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!(average_rating: t.average_rating, total_rating: t.total_rating, user: t.user)} ).sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags =>   @tags } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      if params[:auth_token].present? && params[:date].present?
        current_user = User.find_by_authentication_token(params[:auth_token])
        @tag = Tag.where("close_date is NOT NULL AND user_id = ? AND created_at BETWEEN  ? AND ?", current_user.id, params[:date], DateTime.now )
        if @tags.present?
          @tag = check_followers(@tag, current_user)
          @tags = (@tag.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!(average_rating: t.average_rating, total_rating: t.total_rating, user: t.user)} ).sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }
          get_api_message "200","success"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags =>   @tags } } }
          end
        else
          get_api_message "404","no tag found"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'not found' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
          end
        end
      else
        get_api_message "501","Invalid request"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token] }}}
        end
      end
    end
  end
  def ratings_by_user_PTR
    if params[:auth_token].present? && params[:date].present? && params[:user_id]
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("is_post_to_wall = ? AND created_at BETWEEN  ? AND ? AND user_id = ? AND is_anonymous_rating = ?", true, params[:date], DateTime.now, params[:user_id], false).order("created_at desc")
      #@tag = check_followers(@tag)
      if @rating.present?
        @ratings = @rating.collect { |t| t.attributes.keep_if { |k, v| !["tag_id", "user_id"].include?(k)  }.merge!(tag_line: Tag.find_by_id(t.tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(t.tag_id).average_rating, total_rating: Tag.find_by_id(t.tag_id).total_rating, user: check_user(Tag.find_by_id(t.tag_id).user, current_user) }), comments: t.comments.count, user: t.user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false )  )}.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :ratings =>   @ratings } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      if params[:auth_token].present? && params[:date].present?
        current_user = User.find_by_authentication_token(params[:auth_token])
        @rating = Rating.where("user_id = ? AND created_at BETWEEN  ? AND ?", current_user.id, params[:date], DateTime.now).order("created_at desc").limit(30)
        #@tag = check_followers(@tag)
        if @rating.present?
          @ratings = @rating.collect { |t| t.attributes.keep_if { |k, v| !["tag_id", "user_id"].include?(k)  }.merge!(tag_line: Tag.find_by_id(t.tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(t.tag_id).average_rating, total_rating: Tag.find_by_id(t.tag_id).total_rating, user: check_user(Tag.find_by_id(t.tag_id).user, current_user) }), comments: t.comments.count, user: t.user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false )  )}.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }
          get_api_message "200","success"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :ratings =>   @ratings } } }
          end
        else
          get_api_message "404","no tag found"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'not found' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
          end
        end
      else
        get_api_message "501","Invalid request"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token] }}}
        end

      end
    end
  end
  def taglines_and_ratings_by_user_PTR
    if params[:auth_token].present? && params[:date].present? && params[:user_id]
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("is_post_to_wall = ? AND user_id = ? AND is_anonymous_rating = ? AND created_at BETWEEN  ? AND ?", true, params[:user_id], false, params[:date], DateTime.now).order("created_at desc")
      @tag = Tag.where("is_post_to_wall = ? AND close_date is NOT NULL AND created_at BETWEEN  ? AND ? AND user_id = ?", true, params[:date], DateTime.now, params[:user_id]).order("created_at desc")
      @tag = check_followers(@tag, current_user) if @tag.present?
      @tags_and_ratings = tag_and_ratings @tag, @rating
      if @tags_and_ratings.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }  } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      if params[:auth_token].present? && params[:date].present?
        current_user = User.find_by_authentication_token(params[:auth_token])
        @rating = Rating.where("user_id = ? AND created_at BETWEEN  ? AND ?", current_user.id, params[:date], DateTime.now)
        @tag = Tag.where("close_date is NOT NULL AND created_at BETWEEN  ? AND ? AND user_id = ?", params[:date], DateTime.now, current_user.id)
        @tag = check_followers(@tag, current_user) if @tag.present?
        @tags_and_ratings = tag_and_ratings @tag, @rating
        if @tags_and_ratings.present?
          get_api_message "200","success"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime }  } } }
          end
        else
          get_api_message "404","no tag found"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'not found' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
          end
        end
      else
        get_api_message "501","Invalid request"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token] }}}
        end
      end
    end
  end
  def taglines_and_ratings_by_followings_PTR
    if params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("is_anonymous_rating = ? AND is_post_to_wall = ? AND user_id IN (?)", false, true, UserFollow.where("follow_id = ? AND is_approved = ?", current_user.id, true).pluck(:user_id).uniq).order("created_at desc")
      @tag = Tag.where("close_date is NOT NULL AND is_post_to_wall = ? AND created_at BETWEEN  ? AND ? AND user_id IN (?)", true, params[:date], DateTime.now, UserFollow.where("follow_id = ? AND is_approved = ?", current_user.id, true).pluck(:user_id).uniq)
      @tag = check_followers(@tag, current_user) if @tag.present?
      @tags_and_ratings = tag_and_ratings @tag, @rating
      if @tags_and_ratings.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime } } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token], :date => params[:date] }}}
      end
    end
  end
  def taglines_and_ratings_by_followings_and_me_PTR
    if params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("is_anonymous_rating = ? AND is_post_to_wall = ? AND user_id IN (?)", false, true, UserFollow.where("follow_id = ? AND is_approved = ?", current_user.id, true).pluck(:user_id).uniq) + current_user.ratings
      @tag = Tag.where("close_date is NOT NULL AND is_post_to_wall = ? AND created_at BETWEEN  ? AND ? AND user_id IN (?)", true, params[:date], DateTime.now, UserFollow.where("follow_id = ? AND is_approved = ?", current_user.id, true).pluck(:user_id).uniq) + current_user.tags.where("close_date is NOT NULL AND created_at BETWEEN  ? AND ?", params[:date], DateTime.now )
      @tag = check_followers(@tag, current_user) if @tag.present?
      @tags_and_ratings = tag_and_ratings @tag, @rating
      if @tags_and_ratings.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort! { |a ,b| b["created_at"].to_datetime <=> a["created_at"].to_datetime } } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token], :date => params[:date] }}}
      end
    end
  end
  def tagslines_by_followings
    if params[:auth_token].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @tag = Tag.where(user_id: current_user.id).order("updated_at desc").limit(30)
      if @tag.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :response =>   @tag.map{ |t| t.find_is_tag_line(current_user)  } } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token] }}}
      end
    end
  end
  def ratings_by_followings
    if params[:auth_token].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @tag = Tag.where(user_id: current_user.id).order("updated_at desc").limit(30)
      if @tag.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :response =>   @tag.map{ |t| t.find_is_tag_line(current_user)  } } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token] }}}
      end
    end
  end
  def tagslines_most_popular
    if params[:auth_token].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @tag = Tag.select("*, (SELECT COUNT(*) FROM ratings WHERE ratings.tag_id = tags.id ) AS tags_ratings_total_count").where("is_post_to_wall = ? AND close_date is NOT NULL AND close_date  >= ?", true, DateTime.now).order("tags_ratings_total_count DESC").limit(50)
      if @tag.present?
        @tag = check_followers(@tag, current_user)
        @tags = (@tag.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!(average_rating: t.average_rating, total_rating: t.total_rating, user: t.user)} )
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :most_populat_taglines =>   @tags} } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token] }}}
      end
    end
  end
  def ratings_most_popular
    if params[:auth_token].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("is_post_to_wall = ?", true).limit(30)
      #@tag = check_followers(@tag)
      @ratings = @rating.collect { |t| t.attributes.keep_if { |k, v| !["tag_id", "user_id"].include?(k)  }.merge!(tag_line: Tag.find_by_id(t.tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(t.tag_id).average_rating, total_rating: Tag.find_by_id(t.tag_id).total_rating, user: check_user(Tag.find_by_id(t.tag_id).user, current_user) }), comments: t.comments.count, user: t.user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false )  )}
      if @tag.present?
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :response =>   @tag.map{ |t| t.find_is_tag_line(current_user)  } } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token] }}}
      end
    end
  end
  def taglines_and_ratings_most_popular
    if params[:auth_token].present? && params[:date].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("updated_at < ?", params[:date]).order("rating_like_count DESC")
      @tag = Tag.select("*, (SELECT COUNT(*) FROM ratings WHERE ratings.tag_id = tags.id ) AS tags_ratings_total_count").where("close_date is NOT NULL AND close_date  >= ? AND updated_at BETWEEN  ? AND ?", DateTime.now, params[:date], DateTime.now).order("tags_ratings_total_count DESC")
      @tag = check_followers(@tag, current_user) if @tag.present?
      @tags_and_ratings = tags_and_ratings @tag, @rating
      if @tags_and_ratings.present?
        #@tag = Tag.joins(:ratings).select("*, ( (SELECT SUM(rating) from `ratings` where `tag_id` = `tags`.`id` ) / (SELECT COUNT(*) from `ratings` where `tag_id` = `tags`.`id`) ) AS ss").where("tags.updated_at < ?", params[:date]).order("ss DESC, ratings.rating_like_count DESC").limit(30)
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort_by { |argonite| argonite[:fuck_the_fuckers]}.reverse.first(30) } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      if params[:auth_token].present?
        current_user = User.find_by_authentication_token(params[:auth_token])
        @rating = Rating.order("rating_like_count DESC")
        @tag = Tag.select("*, (SELECT COUNT(*) FROM ratings WHERE ratings.tag_id = tags.id ) AS tags_ratings_total_count").where("close_date is NOT NULL AND close_date  >= ?", DateTime.now).order("tags_ratings_total_count DESC")
        @tag = check_followers(@tag, current_user) if @tag.present?
        @tags_and_ratings = tags_and_ratings @tag, @rating
        if @tags_and_ratings.present?
          get_api_message "200","success"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'tags was successfully sent.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tags_and_ratings =>   @tags_and_ratings.sort_by { |argonite| argonite[:fuck_the_fuckers]}.reverse.first(30) } } }
          end
        else
          get_api_message "404","no tag found"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'not found' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
          end
        end
      else
        get_api_message "501","Invalid request"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token] }}}
        end
      end
    end
  end
  def ratings_of_a_tag_ordered_by_most_popular
    if params[:auth_token].present?  && params[:tag_id].present?
      current_user = User.find_by_authentication_token(params[:auth_token])
      @rating = Rating.where("tag_id = ?", params[:tag_id])
      if @rating.present?
        @ratings = @rating.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!( tag_line: Tag.find_by_id(t.tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(t.tag_id).average_rating, total_rating: Tag.find_by_id(t.tag_id).total_rating, user: check_user(Tag.find_by_id(t.tag_id).user, current_user) }), comments: t.comments.count, user: t.user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false ), most_popular_order: t.most_popular_order )  }.sort_by { |argonite| argonite[:most_popular_order]}.reverse
        get_api_message "200","success"
        respond_to do |format|
          format.html { redirect_to @rating, notice: 'tags was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :ratings_of_a_tag => @ratings } } }
        end
      else
        get_api_message "404","no tag found"
        respond_to do |format|
          format.html { redirect_to @rating, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @rating, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token], :tag_id => params[:tag_id]  }}}
      end
    end
  end
  def check_flag
    if params[:auth_token].present? && params[:request][:box_id].present?
      user = User.find_by_authentication_token params[:auth_token]
      @tag = Tag.find(params[:request][:box_id])
      flagged_box = FlaggedBox.where user_id: user.id, tag_id: @tag.id
      if flagged_box.blank?
        FlaggedBox.create user_id: user.id, tag_id: @tag.id, is_flagged: true
        @tag.update_attribute :is_flagged, true
        if @tag.present?
          get_api_message "200","success"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'Flaged this content.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :tag => @tag.attributes.merge({user: @tag.user}) } } }
          end
        else
          get_api_message "404","no tag found"
          respond_to do |format|
            format.html { redirect_to @tag, notice: 'not found' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
          end
        end
      else
        get_api_message "501","You already flagged the same box"
        respond_to do |format|
          format.html { redirect_to @tag, notice: 'not found' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message}}}
        end
      end
    else
      get_api_message "501","Invalid request"
      respond_to do |format|
        format.html { redirect_to @tag, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message  }}}
      end
    end
  end
  private
  def find_rating(tag)
    total_rating = 0
    #total_count = 0
    #rating = 0
    average_rating = 0
    tag.each do |t|
      total_rating = Tag.find(t).ratings.collect(&:rating).count
      a_rating = Tag.find(t).ratings.collect(&:rating).sum
      average_rating = a_rating / total_rating
      #if t.rating_id.present?
      #  rating = Rating.find(t.rating_id)
      #end
      #if rating.present?
      #  total_rating = tag.count
      #  rating_check = Rating.find_by_tag_id(t.id)
      #  unless rating_check.nil?
      #    total_count = rating_check.rating.to_i + total_count
      #    average_rating = total_count / total_rating
      #  end
      #end
    end
    { rating: { total_rating: total_rating, average_rating: average_rating }}
  end
  def check_followers(tags, current_user)
    @tags = tags.map do |t|
      following_id = UserFollow.where(follow_id: current_user.id, user_id: t.user.id, is_approved: true)
      follow_id = UserFollow.where(follow_id: t.user.id, user_id: current_user.id, is_approved: true)
      if following_id.present?
        t.user.is_following = true
      end
      if follow_id.present?
        t.user.is_follower = true
      end
      t
    end
    @tags || []
  end
  def check_follower(tag, current_user)
    following_id = UserFollow.where(follow_id: current_user.id, user_id: tag.user.id, is_approved: true)
    follow_id = UserFollow.where(follow_id: tag.user.id, user_id: current_user.id, is_approved: true)
    if following_id.present?
      tag.user.is_following = true
    end
    if follow_id.present?
      tag.user.is_follower = true
    end
    tag
  end
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
  def tag_and_ratings tag , rating
    if tag.present? && rating.present?
      @tags_and_ratings = tag.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!(average_rating: t.average_rating, total_rating: t.total_rating, user: t.user)} + rating.collect { |t| t.attributes.keep_if { |k, v| !["tag_id", "user_id"].include?(k)  }.merge!(tag_line: Tag.find_by_id(t.tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(t.tag_id).average_rating, total_rating: Tag.find_by_id(t.tag_id).total_rating, user: check_user(Tag.find_by_id(t.tag_id).user, current_user) }), comments: t.comments.count, user: t.user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false )  )}
    elsif rating.present?
      @tags_and_ratings = rating.collect { |t| t.attributes.keep_if { |k, v| !["tag_id", "user_id"].include?(k)  }.merge!(tag_line: Tag.find_by_id(t.tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(t.tag_id).average_rating, total_rating: Tag.find_by_id(t.tag_id).total_rating, user: check_user(Tag.find_by_id(t.tag_id).user, current_user) }), comments: t.comments.count, user: t.user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false )  )}
    elsif tag.present?
      @tags_and_ratings = tag.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!(average_rating: t.average_rating, total_rating: t.total_rating, user: t.user)}
    else
      []
    end
  end
  def tags_and_ratings tag , rating
    if tag.present? && rating.present?
      @tags_and_ratings = tag.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!( fuck_the_fuckers: t.fuck_the_fuckers , average_rating: t.average_rating, total_rating: t.total_rating, user: t.user)} + rating.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!( tag_line: Tag.find_by_id(t.tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(t.tag_id).average_rating, total_rating: Tag.find_by_id(t.tag_id).total_rating, user: check_user(Tag.find_by_id(t.tag_id).user, current_user) }), comments: t.comments.count, user: t.user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false ), fuck_the_fuckers: t.fuck_the_fuckers )  }
    elsif rating.present?
      @tags_and_ratings = rating.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!( tag_line: Tag.find_by_id(t.tag_id).attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!({ average_rating: Tag.find_by_id(t.tag_id).average_rating, total_rating: Tag.find_by_id(t.tag_id).total_rating, user: check_user(Tag.find_by_id(t.tag_id).user, current_user) }), comments: t.comments.count, user: t.user, is_like: ( UserRating.where(user_id: current_user.id, rating_id: t.id).try(:last).try(:is_like) || false ), fuck_the_fuckers: t.fuck_the_fuckers )  }
    elsif tag.present?
      @tags_and_ratings = tag.collect { |t| t.attributes.keep_if { |k, v| !["user_id"].include?(k)  }.merge!( fuck_the_fuckers: t.fuck_the_fuckers , average_rating: t.average_rating, total_rating: t.total_rating, user: t.user)}
    else
      []
    end
  end
  def check_expiry tag
    time = Time.now - tag.try(:created_at)
    expiry_time = (tag.try(:expiry_time) - time) if tag.try(:expiry_time).present?
    if ( time || 0 < tag.try(:expiry_time))
      # developing the time format for the expiry time handling.
      Time.at(expiry_time.to_i.abs).utc.strftime "%H:%M:%S"
    else
      expiry_time = "expired"
    end
  end
  def get_all_tags
    @tags = Array.new
    Tag.where("close_date is NULL OR close_date >= ?", Date.today).each do |tag|
      time = Time.now - tag.try(:created_at)
      expiry_time = (tag.try(:expiry_time) - time) if tag.try(:expiry_time).present?
      if ( time || 0 < tag.try(:expiry_time))
        @tags << tag
      end
    end
  end
end
