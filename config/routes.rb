Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "pages#home"

  # get '/projects', to: 'projects#index'
  # get '/projects/new', to: 'projects#new'

  resources :projects, only: [:index, :new] do
    post 'new_project_add_project_choice', on: :collection
  end

  get '/students', to: 'students#index'
  get '/issues', to: 'issues#index'
  get '/profile', to: 'profile#index'
  get '/settings', to: 'settings#index'

  get '/facilitators', to: 'facilitators#index'
  get '/facilitators/marking/:module', to: 'facilitators#marking'
  get '/facilitators/team/:id', to: 'facilitators#team'

  resources :admin

end
