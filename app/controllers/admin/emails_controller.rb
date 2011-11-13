class Admin::EmailsController < AdminController
  def index
  end

  def show
    email = Mailer.send(params[:id], *mailer_params(params[:id]))
    render :text => email.body
  end

  private

  def mailer_params(message_id)
    case message_id
      when "response_reminder": [1, fake_emailing, {1 => [2,3,4,5]}]
      when "password_reset": ["a@example.com", "http://example.com/reset/url"]
      when "photo_upload_notification": Photo.last
      when "prediction_progress": [1, fake_emailing, [533998, 102742, 493013, 493012, 137266, 102739]]
      when "share_message": Share.last
      when "share_notification": Share.last
      else nil
    end

  end

  def fake_emailing
    FakeEmailing.new
  end

  class FakeEmailing
    def auto_login_path(path)
      path
    end
  end

end
