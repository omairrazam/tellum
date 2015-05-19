class SendMailToCommentCreator < ActionMailer::Base
  def send_mail_to_comment_creator(current_user_id, rating_creator_user_id, rating_id, anonymous_rating_flag, tellum_host)
    @rating_creator = rating_creator_user_id
    @tellum_host = tellum_host
    @c_user = User.find(current_user_id)
    @current_user_id = current_user_id
    @ratings = Rating.find(rating_id)
    @anonymous_rating_flag = anonymous_rating_flag
    @tag_id = Rating.find(rating_id).tag_id
    @tagline = Tag.find(@tag_id)
    #mail :to => User.find(rating_creator_user_id).email, :from => "admin@tellumapp.com", :subject => "You 've got action!"
    mail :to => User.find(rating_creator_user_id).email, :from => "vf.tellum@gmail.com", :subject => "You 've got action!"
  end
end
