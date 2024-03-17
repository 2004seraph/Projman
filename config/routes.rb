Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "pages#home"

  get '/projects', to: 'projects#index'
  get '/students', to: 'students#index'
  get '/issues', to: 'issues#index'
  get '/profile', to: 'profile#index'
  get '/settings', to: 'settings#index'
end
