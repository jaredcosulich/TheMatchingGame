require 'spec_helper'

describe "links" do
  it "routes /link/:link/:token to links controller" do
    {:get => "/link/foo/123456"}.should route_to(:controller => "links", :action => "index", :link => "foo", :token => "123456")
  end

  it "recognizes" do
    assert_recognizes({:controller => "links", :action => "index", :link => "foo", :token => "token"}, {:path => "/link/foo/token", :method => :get})

  end

  it "generates" do
    assert_generates "/link/foo/token", {:controller => "links", :action => "index", :link => "foo", :token => "token"}
  end

end
