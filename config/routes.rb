Rails.application.routes.draw do
  resource :sessions, only: :show
  get 'auth/callback', to: 'sessions#create'
  root to: 'application#index'
end
