class Api::MessagesController < Api::ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_user!

  def send_message
    user_id = User.find_by_user_name(params[:request][:user_name])
    @user = User.find_by_authentication_token params[:auth_token]
    if user_id.present?
      @user_message = UserMessage.new message: params[:request][:message], receiver_id: user_id.id, sender_id: @user.id
      if @user_message.save
        get_api_message "200","Created"
        respond_to do |format|
          format.html { redirect_to @user_message, notice: 'Message was successfully sent.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :message => @user_message.attributes.keep_if { |k, v| k != "sender_id"  }.merge!({ user: User.find_by_id(@user_message.sender_id).hide_fields }) }   }}
        end
      else
        unless @user_message.errors.empty?
          get_api_message "501","Invalid Request"
          @errors=get_model_error(@user_message)
          return render_errors
        end
        get_api_message "404","Tag could not be sent"
        return render_response
      end
    else
      get_api_message "404","user name not found"
      respond_to do |format|
        format.html { redirect_to @user_message, notice: 'not found.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message } } }
      end
    end
  end
  def messages_list
    if params[:auth_token].present? && params[:user_id].present? && params[:date].present?
      current_user = User.find_by_authentication_token params[:auth_token]
      @message_list1 = UserMessage.where receiver_id:  params[:user_id], created_at: params[:date], sender_id: current_user.id
      @messange_list2 = UserMessage.where receiver_id:  current_user.id, created_at: params[:date], sender_id: params[:user_id]
      @message_list = (@message_list1 + @messange_list2).sort_by { |argonite| argonite["created_at"]}
      if @message_list.present?
        get_api_message "200","Created"
        respond_to do |format|
          #format.html { redirect_to @message_list, notice: 'Message was successfully found.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :messages => @message_list.collect { |t| t.attributes.keep_if { |k, v| k != "sender_id"  }.merge!({ user: User.find_by_id(t.sender_id).hide_fields })   } } } }
        end
      else
        get_api_message "404","no message found for the given user"
        respond_to do |format|
          #format.html { redirect_to @message_list, notice: 'not found.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message} } }
        end
      end
    else
      if params[:auth_token].present? && params[:user_id].present?
        current_user = User.find_by_authentication_token params[:auth_token]
        @message_list1 = UserMessage.where receiver_id:  params[:user_id], sender_id: current_user.id
        @messange_list2 = UserMessage.where receiver_id:  current_user.id, sender_id: params[:user_id]
        @message_list = (@message_list1 + @messange_list2).sort_by { |argonite| argonite["created_at"]}
        if @message_list.present?
          get_api_message "200","Created"
          respond_to do |format|
            #format.html { redirect_to @message_list, notice: 'Message was successfully found.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :messages => @message_list.collect { |t| t.attributes.keep_if { |k, v| k != "sender_id"  }.merge!({ user: User.find_by_id(t.sender_id).hide_fields })   }   } } }
          end
        else
          get_api_message "404","no message found for the given user"
          respond_to do |format|
            #format.html { redirect_to @message_list, notice: 'not found.' }
            format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message} } }
          end
        end
      else
        get_api_message "501","Invalid Request"
        respond_to do |format|
          format.html { redirect_to @message_list, notice: 'Invalid request.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :user_id => params[:user_id], :auth_token => params[:auth_token] } } }
        end
      end
    end
  end
  def messangers_list
    if params[:auth_token].present?
      user = User.find_by_authentication_token params[:auth_token]
      arr1 = Array.new
      recs = user.sent_messages.pluck(:receiver_id).uniq
      recs.each{ |rec| arr1.push( UserMessage.where("sender_id = ? and receiver_id = ?" , user.id , rec).order("created_at DESC").limit(1).first ) }
      sens = UserMessage.where("receiver_id = ?",user.id).pluck(:sender_id).uniq
      sens.each{ |sen| arr1.push( UserMessage.where("sender_id = ? and receiver_id = ?" , sen , user.id).order("created_at DESC").limit(1).first ) }
      @messangers_list = arr1.reject(&:blank?)
      @messangers_list.sort_by! { |m| m.created_at }
      @messangers_list.reverse!
      @messangers_list.each{ |arro| @messangers_list.each{ |arros| @messangers_list.delete(arros) if arros.sender_id == arro.receiver_id && arros.receiver_id == arro.sender_id   }   }
      if @messangers_list.present?
        get_api_message "200","Created #{@sender} and receiver #{@receiver}"
        respond_to do |format|
          format.html { redirect_to @messangers_list, notice: 'successfully found.' }                                                              #@messangers_list.collect { |t| t.attributes.keep_if { |k, v| k != "user_id"  }.merge!({ user: t.user })   }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :messengers => @messangers_list.collect { |t| t.attributes.merge!({ message: t, receiver: User.find_by_id(t.receiver_id).hide_fields, sender: User.find_by_id(t.sender_id).hide_fields  })   }   } } }
        end
      else
        get_api_message "404","no message found for the given user"
        respond_to do |format|
          #format.html { redirect_to @messangers_list, notice: 'not found.' }
          format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message} } }
        end
      end
    else
      get_api_message "501","Invalid Request"
      respond_to do |format|
        #format.html { redirect_to @messangers_list, notice: 'Invalid request.' }
        format.json { render json: {:response => {:status=>@message.status,:code=>@message.code,:message=>@message.custom_message, :auth_token => params[:auth_token] } } }
      end
    end
  end
end
