class Emailing < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  belongs_to :user
  has_one :player, :through => :user
  has_many :links, :as => "source"

  serialize :params

  def name
    "Email: #{email_name}"
  end

  def auto_login_path(path)
    link = links.create(:path => path)
    link_url(:link => link.to_param, :token => user.perishable_token, :host => Emailing.host)
  end

  def facebook_if(college_object, path, college_path)
    if college_object.college_id.present?
      link = auto_login_path(college_path)
      "#{FACEBOOK_CANVAS_PAGE}#{link[link.index(/\/link\//)+1,link.length]}"
    else
      auto_login_path(path)
    end
  end

  def self.host
    Rails.application.host
  end

  def self.deliver(email_name, user_id, *params)
    emailing = Emailing.create(:user_id => user_id, :email_name => email_name, :params => params)
    email = Mailer.send(email_name, user_id, emailing, *params).deliver
    emailing.update_attribute(:body, email.body)
  end

  def redeliver
    Mailer.send(email_name, user_id, self, *params).deliver
    touch
  end
end
