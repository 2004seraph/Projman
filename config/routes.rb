Rails.application.routes.draw do
  root "pages#home"

  resources :projects, only: [:index, :new], controller: :course_projects do
    post 'new_project_add_project_choice', on: :collection
  end
  get '/projects/:id/teams', to: 'lead#teams'

  get '/students', to: 'students#index'
  get '/issues', to: 'issues#index'
  get '/profile', to: 'profile#index'
  get '/settings', to: 'settings#index'

  get '/facilitators', to: 'facilitators#index'
  get '/facilitators/marking/:module', to: 'facilitators#marking'
  get '/facilitators/team/:id', to: 'facilitators#team'

  resources :admin
end
