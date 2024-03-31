Rails.application.routes.draw do
  root "pages#home"
  post '/placeholder_post_url', to: 'dummy#dummy_action'

  resources :projects, only: [:index, :new], controller: :course_projects do
    post 'new_project_add_project_choice', on: :collection
    post 'new_project_remove_project_choice', on: :collection
    post 'new_project_add_project_milestone', on: :collection
    post 'new_project_remove_project_milestone', on: :collection
    post 'new_project_add_to_facilitator_selection', on: :collection
    post 'new_project_remove_from_facilitator_selection', on: :collection
    post 'new_project_add_facilitator_selection', on: :collection
    post 'new_project_remove_facilitator', on: :collection 
    post 'new_project_clear_facilitator_selection', on: :collection
    post 'new_project_toggle_project_choices', on: :collection
    post 'create', on: :collection
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
