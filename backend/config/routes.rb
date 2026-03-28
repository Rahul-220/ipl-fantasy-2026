Rails.application.routes.draw do
  namespace :api do
    resources :users, only: [:index, :create] do
      collection do
        post :login
        post :reset_passwords
      end
    end
    resources :ipl_teams, only: [:index, :show]
    resources :ipl_players, only: [:index, :create, :update, :destroy]

    resources :matches, only: [:index, :show] do
      resources :entries, controller: "match_entries", only: [:index, :create, :show, :destroy]
      member do
        get :leaderboard
      end
    end

    namespace :admin do
      resources :matches, only: [:create] do
        resources :performances, controller: "performances", only: [:index, :create, :update]
        collection do
          post :discover_matches
        end
        member do
          post :calculate_points
          post :update_status
          post :sync_match
          post :toggle_auto_sync
          post :set_cricapi_id
          get :check_status
        end
      end
    end

    get :leaderboard, to: "leaderboard#index"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
