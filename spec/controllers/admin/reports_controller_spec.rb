require 'spec_helper'

describe Admin::ReportsController do
  it "should show" do
    login_as(Factory.create(:admin))
    get :show
    response.should be_success
  end
end
