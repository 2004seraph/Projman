Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "pages#home"

  # get '/projects', to: 'projects#index'
  # get '/projects/new', to: 'projects#new'

  resources :course_projects, only: [:index, :new] do
    post 'new_project_add_project_choice', on: :collection
  end
  get '/projects', to: 'course_projects#index', as: 'projects'
  get '/projects/new', to: 'course_projects#new', as: 'new_project'

  get '/students', to: 'students#index'
  get '/issues', to: 'issues#index'
  get '/profile', to: 'profile#index'
  get '/settings', to: 'settings#index'

  get '/facilitators', to: 'facilitators#index'
  get '/facilitators/marking/:module', to: 'facilitators#marking'
  get '/facilitators/team/:id', to: 'facilitators#team'

  get '/projects/:id/teams', to: 'lead#teams'

  resources :admin

end
