Rails.application.routes.draw do
  devise_for :users

  mount EpiCas::Engine, at: "/"
  root "pages#index"

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
    get 'new_project_search_facilitators', on: :collection
    get 'new_project_get_milestone_data', on: :collection
    post 'new_project_set_milestone_email_data', on: :collection
    post 'new_project_set_milestone_comment', on: :collection
    get 'new_project_search_facilitators_student', on: :collection
    get 'new_project_search_facilitators_staff', on: :collection

    # Define a separate POST route for the 'new' action
    post 'new', to: 'course_projects#create', on: :collection

    get ':id/teams', to: 'lead#teams', on: :collection
    get 'student/:id', to: 'course_projects#show_student', on: :collection
  end

  get '/students', to: 'students#index'

  get '/issues', to: 'issues#index'
  post '/issues/create', to: 'issues#create'
  post '/issues/project-selected', to: 'issues#update_selection'

  get '/profile', to: 'profile#index'
  get '/settings', to: 'settings#index'

  # TEMP: Facilitator routes
  get '/facilitator/teams/:team_id/progress_form/:week', to: 'facilitator#progress_form', as: 'facilitator_progress_form'
  get '/facilitator/marking/:section_id', to: 'facilitator#marking_show', as: 'facilitator_marking_show'

  get '/facilitator/teams/:team_id', to: 'facilitator#team', as: 'facilitator_team'
  post '/facilitator/update_teams_list' => 'facilitator#update_teams_list'

  resources :facilitator

  resources :admin
end
