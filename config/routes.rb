Rails.application.routes.draw do
  resource :sessions, only: :show
  get 'auth/callback', to: 'sessions#create'

  resources :groups, only: [] do
    resources :messages, only: :index
    resource :message_cache, only: [:create, :show]
    resources :most_liked_messages, only: :index
  end

  root to: 'application#index'
end
