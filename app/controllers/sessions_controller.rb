class SessionsController < Devise::SessionsController
  protect_from_forgery except: :create
  skip_before_filter :verify_authenticity_token
  def create
    user = User.authenticate params[:username] , params[:password] rescue ""
    7.times { |i| logger.debug "******#{ user.inspect if i == 4 }*******" }
    if user.blank?
      render :status=>401, :json=>{ status: :error, message: "Invalid Email/Password" }
    else
      render :status=>200, :json=>{:token=> user.authentication_token, status: :ok, message: "Success" }
    end

  end

end
