Rails.application.routes.draw do
  namespace :api do
    resources :orders, only: [:create]

    get 'test/users', to: 'test#users'
    post 'test/reset_cache', to: 'test#reset_cache'
    post 'test/reset_brute_force', to: 'test#reset_brute_force'
  end

  root 'api/test#users'
end
