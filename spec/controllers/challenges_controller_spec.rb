require 'spec_helper'

describe ChallengesController do
  before :each do
    @combo_1 = Factory.create(:response, :photo_one_answer => "good", :photo_two_answer => "good").combo
    @combo_2 = Factory.create(:response, :photo_one_answer => "bad").combo
    @combo_3 = Factory.create(:combo)
    @combo_4 = Factory.create(:combo)

    @challenge = Factory.create(:challenge)
    @challenge.challenge_combos.create(:combo => @combo_1)
    @challenge.challenge_combos.create(:combo => @combo_2)
    @challenge_player = @challenge.challenge_players.create!(:name => "name", :email => "challenged@example.com")
  end

  describe "accepted" do
    before :each do
      @challenge_player.find_or_create_player
    end

    describe "index" do
      it "should show challenges you created" do
        set_session_for_player(@challenge.creator)

        get :index

        assigns[:challenges].should == [@challenge]
      end

      it "should show challenges you are a player in" do
        set_session_for_player(@challenge_player.player)

        get :index

        assigns[:challenges].should == [@challenge]
      end

      it "should be empty if new player" do
        get :index

        assigns[:challenges].should be_empty
      end
    end

    describe "new" do
      it "should render and build a template player and a creator player" do
        player = set_session_for_player(Factory.create(:player))

        get :new

        response.should be_success
        assigns[:challenge].creator.should == player
        assigns[:challenge].challenge_players.length.should == 2
      end

      it "should populate first player from creator" do
        player = set_session_for_player(Factory.create(:full_player))

        get :new

        response.should be_success
        assigns[:challenge].creator.should == player
        assigns[:challenge].challenge_players.length.should == 2

        creator = assigns[:challenge].challenge_players.first
        creator.email.should == player.email
        creator.name.should == player.full_name

        template = assigns[:challenge].challenge_players.last
        template.email.should be_blank
        template.name.should be_blank
      end

      it "should be able to clone an existing challenge with a potentially new creator" do
        set_session_for_player(@challenge_player.player)
        get :new, :from => @challenge.to_param

        response.should be_success
        assigns[:challenge].creator.should == @challenge_player.player
        assigns[:challenge].challenge_players.length.should == 3
        
        creator = assigns[:challenge].challenge_players.first
        creator.email.should == @challenge_player.player.email
        creator.name.should == @challenge_player.name

        other_player = assigns[:challenge].challenge_players[1]
        other_player.email.should == @challenge.creator.email
        other_player.name.should == @challenge.challenge_player_for(@challenge.creator).name

        template = assigns[:challenge].challenge_players.last
        template.email.should be_blank
        template.name.should be_blank

      end

    end

    describe "create" do
      it "should save the challenge and redirect to show" do
        creator = set_session_for_player(Factory.create(:full_player))

        post :create, {:challenge => {:name => "John's renamed Challenge", :challenge_players_attributes =>
        {"0"=>{"name"=>"", "email"=>""},
         "1"=>{"name"=> creator.full_name, "email" => creator.email},
         "2"=>{"name"=>"Player Two", "email"=>"two@example.com"},
         "3"=>{"name"=>"Player Three", "email"=>"three@example.com"}}}}

        challenge = Challenge.last

        response.should redirect_to(challenge_path(challenge))

        challenge.creator.should == creator
        challenge.name.should == "John's renamed Challenge"
        challenge.challenge_players.length.should == 3
        challenge.challenge_players.collect(& :name).should == ["first", "Player Two", "Player Three"]

      end

      it "should render new with errors if not valid" do
        set_session_for_player(Factory.create(:full_player))

        post :create, {:challenge => {:name => "", :challenge_players_attributes =>
          {"0"=>{"name"=>"", "email"=>""},
           "2"=>{"name"=>"", "email"=>"one@example.com"},
           "3"=>{"name"=>"Player Two", "email"=>""},
           "4"=>{"name"=>"Player Three", "email"=>"three@example.com"}}}}

        response.should render_template(:new)

        assigns[:challenge].challenge_players.first.errors_on(:name).should be_present
      end

      it "should redirect to new if no challenges specified" do
        creator = set_session_for_player(Factory.create(:full_player))

        post :create, {:challenge => {:name => "", :challenge_players_attributes =>
          {"0"=>{"name"=>creator.full_name, "email"=>creator.email},
           "2"=>{"name"=>"", "email"=>""},
           "3"=>{"name"=>"", "email"=>""},
           "4"=>{"name"=>"", "email"=>""}}}}

        response.should redirect_to(new_challenge_path)
      end
    end

    describe "play" do
      before :each do
        set_session_for_player(@challenge_player.player)
      end

      it "should play a game" do
        get :play, :id => @challenge.to_param
        assigns[:challenge].should == @challenge
        assigns[:game].challenge_player_id.should == @challenge_player.id
        assigns[:game].player.should == @challenge_player.player
        assigns[:challenge_combo_combos].map(&:id).sort.should == [@combo_1.id, @combo_2.id, @combo_3.id, @combo_4.id]
      end

      describe "in progress" do
        before :each do
          @game = @challenge_player.create_game
          @game.answers.create(:combo => @combo_1, :answer => 'y', :player => @game.player)
          @game.answers.create(:combo => @combo_4, :answer => 'n', :player => @game.player)
        end

        it "should not show already answered combos, with the challenge combo first" do
          get :play, :id => @challenge.to_param

          assigns[:challenge_combo_combos].should == [@combo_2, @combo_3]
        end

        it "should redirect to the games/show and flash if you've finished the game and tried to play again" do
          @game.answers.create(:combo => @combo_2, :answer => 'y')
          @game.answers.create(:combo => @combo_3, :answer => 'y')

          get :play, :id => @challenge.to_param

          response.should redirect_to(challenge_path(@challenge))
          flash[:notice].should =~ /complete/
        end
      end
    end

    describe "show" do
      before :each do
        ActiveRecord::Observer.with_observers(:game_observer) do
          @third_player = @challenge.challenge_players.create!(:name => "Adam", :email => "adam@example.com")
          @third_player.find_or_create_player
          @creator_player = @challenge.challenge_player_for(@challenge.creator)

          @creator_game = @creator_player.create_game
          @creator_game.answers.create(:combo => @combo_1, :answer => 'y')
          @creator_game.answers.create(:combo => @combo_2, :answer => 'y')

          @player_game = @challenge_player.create_game

          @third_player_game = @third_player.create_game
          @third_player_game.answers.create(:combo => @combo_1, :answer => 'y')
          @third_player_game.answers.create(:combo => @combo_2, :answer => 'n')
        end
      end

      it "should sort players by score" do
        set_session_for_player(@creator_player.player)
        get :show, :id => @challenge.to_param
        assigns[:ranked_players].map(&:id).should == [@third_player.id, @creator_player.id, @challenge_player.id]
      end

      describe "for non participants" do
        it "should redirect if the challenge is not complete" do
          get :show, :id => @challenge.to_param
          response.should redirect_to(root_path)
        end

        it "should show if the challenge is complete" do
          ActiveRecord::Observer.with_observers(:game_observer) do
            @challenge_player_game = @challenge_player.create_game
            @challenge_player_game.answers.create(:combo => @combo_1, :answer => 'y')
            @challenge_player_game.answers.create(:combo => @combo_2, :answer => 'n')
            @challenge_player_game.answers.create(:combo => @combo_3, :answer => 'n')
            @challenge_player_game.answers.create(:combo => @combo_4, :answer => 'n')

            @creator_game.answers.create(:combo => @combo_3, :answer => 'n')
            @creator_game.answers.create(:combo => @combo_4, :answer => 'n')

            @third_player_game.answers.create(:combo => @combo_3, :answer => 'n')
            @third_player_game.answers.create(:combo => @combo_4, :answer => 'n')
          end

          get :show, :id => @challenge.to_param

          response.should be_success
        end
      end
    end
  end

  describe "accept" do
    it "should create new player and user when visiting via link for first time" do
      @challenge_player.player.should be_nil

      get :accept, :id => @challenge.to_param, :token => @challenge_player.token

      response.should redirect_to challenge_path(@challenge)

      @challenge_player.reload
      @challenge_player.player.should be_present
      @challenge_player.player.email.should == "challenged@example.com"
      assigns[:current_player].should == @challenge_player.player
    end

    it "should handle already logged in" do
      player = set_session_for_player(Factory.create(:player))
      player.email.should be_blank
      new_challenge_player = @challenge.challenge_players.create(:name => "Joe", :email => "joe@example.com")

      get :accept, :id => @challenge.to_param, :token => new_challenge_player.token

      response.should redirect_to challenge_path(@challenge)
      assigns[:current_player].should be_present
      assigns[:current_player].should == player
      assigns[:current_player].should == new_challenge_player.reload.player
      assigns[:current_player].email.should == "joe@example.com"
    end

    it "should log you in as the challenge_player's player when present, even if logged in" do
      player = set_session_for_player(Factory.create(:user, :email => "not_joe@example.com").player)

      new_challenge_player = @challenge.challenge_players.create(:name => "Joe", :email => "joe@example.com")
      get :accept, :id => @challenge.to_param, :token => new_challenge_player.token

      response.should redirect_to challenge_path(@challenge)
      assigns[:current_player].should be_present
      assigns[:current_player].should_not == player
      assigns[:current_player].should == new_challenge_player.reload.player

      assigns[:current_player].user.email.should == "joe@example.com"
    end

    it "should log you in as the existing player if an existing player exists" do
      joe_player = Factory.create(:user, :email => "joe@example.com").player
      not_joe_player = set_session_for_player(Factory.create(:user, :email => "not_joe@example.com").player)

      new_challenge_player = @challenge.challenge_players.create(:name => "Joe", :email => "joe@example.com")
      get :accept, :id => @challenge.to_param, :token => new_challenge_player.token

      response.should redirect_to challenge_path(@challenge)
      assigns[:current_player].should be_present
      assigns[:current_player].should_not == not_joe_player
      assigns[:current_player].should == joe_player
      joe_player.should == new_challenge_player.reload.player

      assigns[:current_player].user.email.should == "joe@example.com"
    end
  end
end
