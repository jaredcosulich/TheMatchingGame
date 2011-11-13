Match3::Application.routes.draw do

  root :to => "home#index"

  match '/safari' => "home#safari", :as => "safari"
  match '/feedback' => "home#feedback", :method => :post, :as => "feedback"
  match '/success_story' => "home#feedback", :method => :post, :as => "success_story"
  match '/spread_the_word' => "home#spread_the_word", :method => :post, :as => "spread_the_word"
  match '/link/:link/:token' => "links#index", :as => "link"
  match '/close' => "home#close", :as => "close"
  match '/college/close' => "home#close", :as => "college_close"

  resource :session

  resource :account do
    member do
      post :help_response
    end
    resource :profile do
      member do
        post :facebook
      end
    end
  end

  resource :register

  resources :shares
  resource :password_reset
  resources :players

  resources :matchmakers, :only => [:index]

  resources :best_words

  resources :priorities

  resources :want_payments

  resource :credits do
    member do
      get :complete
      get :watch
      get :earn
      get :work
    end
  end

  resource :answers do
    member do
      get :query
    end
  end

  resources :games do
    member do
      post :more_combos
    end
    collection do
      get  :leaderboard      
    end
    resource :answers, :controller => "game_answers"
  end

  match '/dating/labs' => 'profile_game#labs', :as => "labs"
  match '/dating/profile' => 'profile_game#index', :as => "profile_game"
  match '/dating/interests' => 'profile_game#interests', :as => "profile_game_interests"
  match '/dating/discover' => 'profile_game#discover', :as => "profile_game_discover"
  match '/dating/innovative' => 'profile_game#innovative', :as => "innovative_dating"
  match '/dating/discounts' => 'profile_game#discounts', :as => "dating_discounts"
  match "/dating" => redirect("/")

  resource :map
  resources :questions do
    resources :question_answers
    member { get :player }
  end

  resources :clubs do
    member { get :photo }
    member { post :join }
    collection { get :all }
    collection {get :popular}
  end

  resources :match_me do
    member { get :play }
    member { get :friends }
    resources :games, :controller => "match_me_games" do
      member { post :answers }
    end
  end


  resources :challenges do
    member do
      get :play
      get :accept
      post :remove_challenger
    end
  end

  resources :photos do
    member do
      put :confirm
      post :pause
      post :resume
      post :remove
      put :update_player
    end

    collection do
      post :facebook
    end
  end

  resources :couples do
    member do
      post :add_couple_friend
    end
    resources :couple_friends
  end

  resources :combos do
    resource :response, :controller => "combo_responses"
  end

  resources :connections do
    member do
      post :action
      post :connect
      put  :archive
      get  :connect
      get  :unlock
    end
  end


  match 'jobs/:action', :controller => "crowdflower_jobs"
  match 'tapjoy', :controller => "tapjoy", :action => :complete
  match 'jun', :controller => "jun", :action => :complete

  namespace :admin do
    root :to => "admin#index"
    resources :approvals do
      collection do
        post :bulk
      end
    end

    resources :questions
    
    resources :clubs do
      member {post :set_club}
    end

    resources :profile_games

    resources :dashboards do
      collection {get :matching}
      collection {get :analytics}
    end

    resources :transactions

    resources :photos do
      collection do
        get :good
      end

      member do
        get :initial
        get :crop
        put :crop
        get :photo_pairs
        get :correlations
        get :new_combos
      end
    end

    resources :smarter_clusters do
      collection do
        get :delta
      end
    end

    resources :responses do
      collection do
        get :progress
      end
    end

    resources :request_logs do
      resources :details, :controller => "request_log_details"
    end

    resource :reports do
      member do
        get :help_responses
      end
    end

    resource :sample_games do
      member do
        get :challenge
      end
    end

    resources :shares do
      member do
        post :approve
        post :reject
      end
    end

    resources :players do
      member { post :impersonate }
      member { get :emails }
      collection { get :all_photos_removed }
      collection { get :deleted_accounts }
      collection { get :map }
    end

    resources :photo_pairs do
      collection { get :popular_photos }
    end

    resources :combos do
      collection { get :great_combos }
      collection { get :fake_predicted }
    end

    resources :clusters
    resources :emails
    resources :emailings
    resources :referrers
    resources :links

    resources :games

    resources :facebook_users
  end

  resource :about, :controller => 'about' do
    member do
      get :tos
      get :privacy
      get :oops
    end
  end


  namespace :college do
    root :to => "home#index"
    match '/frame' => "home#frame", :as => "college_frame"
    match '/not_ready' => "home#not_ready"
    match '/link/:link/:token' => "links#index", :as => "link"
    resources :photos, :only => [:index, :new, :create]
    resources :connections, :only => :index do
      member do
        post :action
        post :connect
        put  :archive
        get  :connect
      end
    end
    resources :rankings, :only => :index
    resources :users, :only => [:index, :update]
  end

end
