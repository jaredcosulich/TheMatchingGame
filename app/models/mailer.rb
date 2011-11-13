class Mailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper

  ADMIN_EMAILS = ["jared@thematchinggame.com"]
  default_url_options[:host] = Emailing.host
  default :from => "The Matching Game <support@thematchinggame.com>", :headers => {'X-SMTPAPI' => '{"category": "MatchingGame"}'}#, :bcc => "emails@thematchinggame.com"

  def notify_unconfirmed(user_id, emailing, photo_id)
    @photo = Photo.find(photo_id)
    @recipient = @photo.player
    @name = @recipient.first_name

    @emailing = emailing
    record_mailing(@recipient.user)
    mail(
      :to => filter_recipients(nice_email_address_for_user(@recipient.user)),
      :subject => "#{@recipient.first_name.blank? ? "Y" : "#{@recipient.first_name}, y"}ou have an unconfirmed photo on The Matching Game"
    )

  end

  def combo_action_notification(user_id, emailing, combo_action_id)
    @action = ComboAction.find(combo_action_id, :include => [{:photo => :player}, {:combo => [{:photo_one => {:player => :user}}, {:photo_two => {:player => :user}}]}])
    @recipient = @action.combo.other_photo(@action.photo).player
    @author = @action.actor
    @name = @recipient.first_name
    @action_from = @author
    @show_message = @action.visible_to?(@recipient)

    @emailing = emailing
    record_mailing(@recipient.user)
    mail(
      :to => filter_recipients(nice_email_address_for_user(@recipient.user)),
      :subject => "#{@recipient.first_name.blank? ? "Y" : "#{@recipient.first_name}, y"}ou have a new message#{" from #{@author.first_name}" unless @author.first_name.blank?} on The Matching Game"
    )
  end

  def open_messaging_announcement(user_id, emailing)
    @recipient = User.find(user_id)
    @emailing = emailing
    mail(
      :to => filter_recipients(nice_email_address_for_user(@recipient)),
      :subject => "Happy New Year! Free messaging on The Matching Game"
    )
  end

  def interested_notification(user_id, emailing, combo_id)
    @combo = Combo.find(combo_id, :include => [{:photo_one => {:player => :user}}, {:photo_two => {:player => :user}}])
    @recipient = [@combo.photo_one.player.user, @combo.photo_two.player.user].select { |u| u.id == user_id }.first.player
    @author = @combo.other_actor(@recipient)
    @emailing = emailing
    record_mailing(@recipient.user)
    mail(
      :to => filter_recipients(nice_email_address_for_user(@recipient.user)),
      :subject => "#{@recipient.first_name.blank? ? "O" : "#{@recipient.first_name}, o"}ne of your matches#{", #{@author.first_name}," unless @author.first_name.blank?} wants to connect with you on The Matching Game!"
    )
  end

  def mutual_good_notification(user_id, emailing, combo_id)
    @combo = Combo.find(combo_id, :include => [{:photo_one => {:player => :user}}, {:photo_two => {:player => :user}}])
    @recipient = [@combo.photo_one.player.user, @combo.photo_two.player.user].select { |u| u.id == user_id }.first.player
    @author = @combo.other_actor(@recipient)
    @emailing = emailing
    record_mailing(@recipient.user)
    mail(
      :to => filter_recipients(nice_email_address_for_user(@recipient.user)),
      :subject => "You and #{@author.first_name.blank? ? "one of your matches" : @author.first_name} both thought you were a good match for each other!"
    )
  end

  def mutual_good_not_connected_notification(user_id, emailing, combo_id)
    @combo = Combo.find(combo_id, :include => [{:photo_one => {:player => :user}}, {:photo_two => {:player => :user}}])
    @recipient = [@combo.photo_one.player.user, @combo.photo_two.player.user].select { |u| u.id == user_id }.first.player
    @author = @combo.other_actor(@recipient)
    @emailing = emailing
    record_mailing(@recipient.user)
    mail(
      :to => filter_recipients(nice_email_address_for_user(@recipient.user)),
      :subject => "You and #{@author.first_name.blank? ? "one of your matches" : @author.first_name} both thought you were a good match for each other!"
    )
  end

  def password_reset(email, password_reset_url)
    @password_reset_url = password_reset_url

    mail(
      :to => filter_recipients(email),
      :subject => "Reset your password for The Matching Game"
    )
  end

  def rejection_reason(user_id, emailing, photo)
    @photo = photo
    @emailing = emailing
    mail(
      :to => filter_recipients(User.find(user_id).email),
      :subject => "There is a problem with your photo - The Matching Game"
    )
  end

  def photo_approved(user_id, emailing, photo)
    @photo = photo
    @emailing = emailing
    mail(
      :to => filter_recipients(User.find(user_id).email),
      :subject => "Your photo has been approved - The Matching Game"
    )
  end

  def photo_upload_notification(photo)
    @photo = photo
    mail(
      :to => filter_recipients(ADMIN_EMAILS),
      :subject => "A new photo has been uploaded"
    )
  end

  def admin_notification(params)
    @params = params
    mail(
      :to => filter_recipients(ADMIN_EMAILS),
      :subject => "admin info notification #{params[:subject]}"
    )
  end

  def share_notification(share_id)
    @share = Share.find(share_id)
    @host = Emailing.host
    mail(
      :to => filter_recipients(ADMIN_EMAILS),
      :subject => "A new share has been created"
    )
  end

  def share_message(share_id)
    share = Share.find(share_id)
    share.sent!
    @message_content = share.message
    mail(
      :to => filter_recipients(share.emails),
      :subject => "#{share.from} wants you to try out The Matching Game"
    )
  end

  def restock_report(disabled, added, time, timings)
    @disabled = disabled
    @added = added
    @time = time
    @timings = timings
    @host = Emailing.host

    mail(
      :to => filter_recipients(ADMIN_EMAILS),
      :subject => "#{Rails.env.capitalize} Restock Report for #{Date.today.strftime('%F')}"
    )
  end

  def response_reminder(user_id, emailing, photo_photo_ids)
    @matches_count = 0
    @user = User.find(user_id)
    @photo_photos = {}
    photo_photo_ids.each_pair do |photo_id, other_photo_ids|
      @photo_photos[Photo.find(photo_id)] = other_photo_ids[0..2].collect { |id| Photo.find(id) }
      @matches_count += other_photo_ids.length
    end
    @name = @user.player.first_name
    @emailing = emailing
    record_mailing(@user)
    mail(
      :to => filter_recipients(nice_email_address_for_user(@user)),
      :subject => "#{"#{@name}, " unless @name.blank?}You have #{@matches_count} new match#{'es' if @matches_count > 1} - The Matching Game"
    )
  end

  def other_photo_match_reminder(user_id, emailing, photo_photo_ids)
    @matches_count = 0
    @user = User.find(user_id)
    @photo_photos = {}
    photo_photo_ids.each_pair do |photo_id, other_photo_ids|
      @photo_photos[Photo.find(photo_id)] = other_photo_ids[0..2].collect { |id| Photo.find(id) }
      @matches_count += other_photo_ids.length
    end
    @name = @user.player.first_name
    @emailing = emailing

    @matches_text = (@user.player.gender == "f" ? (pluralize(@matches_count, "handsome gentleman", "handsome gentlemen")) : (pluralize(@matches_count, "lovely lady", "lovely ladies")))
    @matches_pronoun = @matches_count > 1 ? "they" : (@user.player.gender == "f" ? "he" : "she")
    record_mailing(@user)
    mail(
      :to => filter_recipients(nice_email_address_for_user(@user)),
      :subject => "#{"#{@name}, " unless @name.blank?} #{@matches_text} thought #{@matches_pronoun} might be a good match for you  - The Matching Game"
    )
  end

  def send_challenge_email(challenge_player_id, subject = nil)
    @challenge_player = ChallengePlayer.find(challenge_player_id, :include => :challenge)
    @challenge = @challenge_player.challenge

    @host = Emailing.host

    mail(
      :to => filter_recipients(nice_email_address(@challenge_player.email, @challenge_player.name)),
      :subject => subject || "#{"#{@challenge_player.name}, " unless @challenge_player.name.blank?}#{@challenge.creator.full_name} has challenged you.",
      :reply_to => nice_email_address(@challenge.creator.email, @challenge.creator.full_name)
    )
  end

  def challenge_creator_invitation(challenge_player_id)
    send_challenge_email(challenge_player_id, "Your Matchmaking Challenge has been created")
  end

  def challenge_player_invitation(challenge_player_id)
    send_challenge_email(challenge_player_id)
  end

  def challenge_player_completed(challenge_player_id)
    @challenge_player = ChallengePlayer.find(challenge_player_id, :include => :challenge)
    @challenge = @challenge_player.challenge
    @creator = @challenge.creator

    @host = Emailing.host

    mail(
      :to => filter_recipients(nice_email_address(@creator.email, @creator.full_name)),
      :subject => "#{@challenge_player.name} has completed your challenge"
    )
  end

  def challenge_complete(user_id, emailing, challenge_player_id)
    @challenge_player = ChallengePlayer.find(challenge_player_id, :include => [:challenge, {:player => :user}])
    @challenge = @challenge_player.challenge

    @emailing = emailing
    message_recipients = @challenge.challenge_players.collect{ |cp| nice_email_address(cp.player.email, cp.name) }
    mail(
      :to => filter_recipients(nice_email_address(@challenge_player.player.email, @challenge_player.name)),
      :subject => "#{@challenge.name} is complete!",
      :reply_to => message_recipients
    )
  end

  def couple_complete(user_id, emailing, couple_combo_id)
    @user = User.find(user_id)
    @couple_combo = Combo.find(couple_combo_id, :include => {:photo_one => {:player => :user}})
    @friend = @couple_combo.photo_one.player.user != @user
    @emailing = emailing
    mail(
      :to => filter_recipients(nice_email_address_for_user(@user)),
      :subject => "Voting has completed on your #{"friends' " if @friend}Perfect Pair Challenge entry!"
    )
  end

  def prediction_progress(user_id, emailing, responded_to_ids)
    @responded_tos = responded_to_ids.empty? ? [] : Answer.find(:all, :conditions => "id in (#{responded_to_ids.join(',')})")
    @user = User.find(user_id)
    @name = @user.player.first_name

    @emailing = emailing
    record_mailing(@user)
    mail(
      :to => filter_recipients(nice_email_address_for_user(@user)),
      :subject => "The fruits of your matchmaking efforts: #{@responded_tos.length} matches answered."
    )
  end

  def nice_email_address_for_user(user)
    nice_email_address(user.email, user.player.full_name)
  end

  def nice_email_address(email, name)
    "#{"#{name}" unless name.blank?} <#{email}>"
  end

  def filter_recipients(recipients)
    if Rails.env.production? || Rails.env.test?
      recipients
    else
      "\"#{recipients}\" <emails@thematchinggame.com>"
    end
  end

  def record_mailing(user)
    user.update_attributes(:last_emailed_at => Time.new, :emails_sent => user.emails_sent + 1)
  end
end
