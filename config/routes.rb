Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#show"

  get  "play/:code", to: "play#show", as: :play
  post "play/:code", to: "play#create"

  resources :responses, only: [ :create ]

  resources :games, only: [ :show, :create ] do
    member do
      post :start
      post :advance
      post :finish_question
    end
  end

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  mount Litestream::Engine, at: "/litestream" if Rails.env.development?
end
