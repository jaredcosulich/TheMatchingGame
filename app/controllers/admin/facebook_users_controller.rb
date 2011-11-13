class Admin::FacebookUsersController < AdminController
  def index
    @test_users = test_users
  end

  def create
    create_test_user
    redirect_to admin_facebook_users_path
  end

  def destroy
    delete_user(params["id"], params["access_token"])
    redirect_to admin_facebook_users_path
  end

  private
  def test_users
    url = "https://graph.facebook.com/#{FACEBOOK_APP_ID}/accounts/test-users?#{application_access_token}"
    JSON.parse(RestClient.get(URI.escape url).body)['data']
  end

  def delete_user(id, access_token)
    RestClient.delete(URI.escape "https://graph.facebook.com/#{id}?access_token=#{access_token}")
  end

  def application_access_token
    RestClient.post "https://graph.facebook.com/oauth/access_token",:grant_type => "client_credentials", :client_id => FACEBOOK_APP_ID, :client_secret => FACEBOOK_APP_SECRET
  end

  def create_test_user
    RestClient.post "https://graph.facebook.com/#{FACEBOOK_APP_ID}/accounts/test-users", {:installed => false, :access_token => application_access_token.split(/=/).last}
  end
end
