class SendMailToTagCreator < ActionMailer::Base
  def send_tag_creator(current_user_id, tag_creator_user_id, tag_id, anonymous_rating_flag, tellum_host)
    @tag_creator = tag_creator_user_id
    @tellum_host = tellum_host
    @c_user = User.find(current_user_id)
    @tag_line = Tag.find(tag_id)
    @anonymous_rating_flag = anonymous_rating_flag
#    mail :to => User.find(tag_creator_user_id).email, :from => "admin@tellumapp.com", :subject => "New Drop in Your Box!"
    mail :to => User.find(tag_creator_user_id).email, :from => "vf.tellum@gmail.com", :subject => "New Drop in Your Box!"
  end
end
