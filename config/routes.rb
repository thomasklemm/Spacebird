require 'sidekiq/web'

Knight::Application.routes.draw do
  # Devise authentication for subscribers
  devise_for  :subscribers,
              path_names:  {sign_in: 'login', sign_out: 'logout'},
              controllers: {omniauth_callbacks: 'omniauth'} do
    get 'login', to: 'devise/sessions#new', as: :new_subscriber_session
    get 'logout', to: 'devise/sessions#destroy', as: :destroy_subscriber_session
  end

  # Sidekiq Web Interface
  # FIXME: The Sidekiq Interface needs authentication
  mount Sidekiq::Web, at: '/sidekiq', as: :sidekiq

  # Static Pages
  match '/:id' => 'high_voltage/pages#show', as: :static, via: :get

  # Root
  # (also required for devise)
  root to: 'high_voltage/pages#show', id: 'index'
end
