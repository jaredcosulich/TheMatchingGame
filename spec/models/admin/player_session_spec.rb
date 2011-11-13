require 'spec_helper'

describe Admin::PlayerSession do
  before :each do
    @log_requests = [
     {"value"=>"/",            "key"=>[234, "2010/05/27 12:34:47"]},
     {"value"=>"/",            "key"=>[234, "2010/05/27 12:34:49"]},
     {"value"=>"/session/new", "key"=>[234, "2010/05/27 12:34:54"]},
     {"value"=>"/",            "key"=>[234, "2010/05/27 12:34:57"]},
     {"value"=>"/",            "key"=>[234, "2010/05/27 14:56:00"]},
     {"value"=>"/session",     "key"=>[234, "2010/05/27 14:56:11"]},
   ]
   @player_sessions = Admin::PlayerSession.parse(@log_requests)
  end

  it "should parse log requests into sessions" do
    @player_sessions.length.should == 2
    @player_sessions.first.infos.length.should == 4
    @player_sessions.first.start_time.should == Time.parse("2010/05/27 12:34:47")
    @player_sessions.last.infos.length.should == 2
    @player_sessions.last.start_time.should == Time.parse("2010/05/27 14:56:00")
  end

  it "should calculate time on page" do
    @player_sessions.first.infos[0].duration.should == 2
    @player_sessions.first.infos[1].duration.should == 5
    @player_sessions.first.infos[2].duration.should == 3
    @player_sessions.first.infos[3].duration.should be_nil
    @player_sessions.first.duration.should == 10
  end
end
