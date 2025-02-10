Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, only: [ :index, :show, :update, :destroy ]
      resources :bicycles, only: [ :show, :create, :update, :destroy ]

      devise_for :users,
        controllers: {
          sessions: "api/v1/users/sessions",
          registrations: "api/v1/users/registrations"
        },
        path: "users",
        path_names: {
          sign_in: "sign_in",
          sign_out: "sign_out",
          sign_up: "sign_up"
        }
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
