Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, only: [ :index, :show, :update, :destroy ]
      resources :bicycles, only: [ :show, :create, :update, :destroy ]

      devise_for :users,
      path: "",
      path_names: {
        sign_in: "login",
        sign_out: "logout",
        registration: "register"
      },
      controllers: {
        sessions: "api/v1/users/sessions",
        registrations: "api/v1/users/registrations"
      }
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
