Rails.application.routes.draw do
  devise_for :users

  mount EpiCas::Engine, at: "/"
  root "page#index"

  resources :projects, controller: :course_project do
    post 'add_project_choice', on: :collection
    post 'remove_project_choice', on: :collection
    post 'add_project_milestone', on: :collection
    post 'remove_project_milestone', on: :collection
    post 'add_to_facilitator_selection', on: :collection
    post 'remove_from_facilitator_selection', on: :collection
    post 'add_facilitator_selection', on: :collection
    post 'remove_facilitator', on: :collection
    post 'clear_facilitator_selection', on: :collection
    post 'toggle_project_choices', on: :collection
    get 'search_facilitators', on: :collection
    get 'get_milestone_data', on: :collection
    post 'set_milestone_email_data', on: :collection
    post 'set_milestone_comment', on: :collection
    get 'search_facilitators_student', on: :collection
    get 'search_facilitators_staff', on: :collection

    # Define a separate POST route for the 'new' action

    get '/teams', to: 'lead#teams', on: :member
  end

  get '/students', to: 'student#index'

  get '/issues', to: 'issue#index'
  post '/issues/create', to: 'issue#create'
  post '/issues/project-selected', to: 'issue#update_selection'

  get '/profile', to: 'profile#index'
  get '/settings', to: 'setting#index'

  # TEMP: Facilitator routes
  resources :facilitator, only: [:index]
  get '/facilitator/teams/:team_id/progress_form/:week', to: 'facilitator#progress_form', as: 'facilitator_progress_form'
  get '/facilitator/marking/:section_id', to: 'facilitator#marking_show', as: 'facilitator_marking_show'
  get '/facilitator/teams/:team_id', to: 'facilitator#team', as: 'facilitator_team'
  post '/facilitator/update_teams_list' => 'facilitator#update_teams_list'

  resources :admin
end
