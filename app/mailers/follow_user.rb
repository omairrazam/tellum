class FollowUser < ActionMailer::Base
  def follow_user(current_user_id, user_id, tellum_host)
    @user = User.find(user_id).is_public_profile
    @tellum_host = tellum_host
    @c_full_name = User.find(current_user_id).full_name
    @c_user_name = User.find(current_user_id).user_name
    @c_user_id = current_user_id
    mail :to => User.find(user_id).email, :from => "vf.tellum@gmail.com", :subject => "Tellum - Follow"
  end
end
