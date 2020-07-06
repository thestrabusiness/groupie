Rails.application.routes.draw do
  root to: 'application#index'

  resource :sessions, only: [:show, :destroy]
  get 'auth/callback', to: 'sessions#create'

  resources :groups, only: [] do
    # resources :messages, only: :index
    resource :message_cache, only: [:create, :show]
    resources :most_liked_messages, only: :index
  end

  get '*destination', to: 'application#index'
end
