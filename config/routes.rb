Rails.application.routes.draw do
  devise_for :users

  mount EpiCas::Engine, at: "/"

  root "page#index"

  get '/profile', to: 'page#profile'
  get '/mailing', to: 'page#mailing'

  resources :projects, controller: :course_project do

    resource :milestone_responses, only: [:create], controller: :milestone_response

    get '/teams', to: 'lead#teams', on: :member
    post '/new', to: 'course_project#create', on: :collection

    # AJAX
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
    get 'search_student_name', on: :collection
  end

  resources :students, only: [:index], controller: :student do
  end

  resources :issues, only: [:index, :create], controller: :issue do
    # AJAX
    post 'update-selection', to: 'issue#update_selection', on: :collection
    post 'issue-response', to: 'issue#issue_response', on: :collection
    post 'update-status', to: 'issue#update_status', on: :collection
  end

  resources :facilitators, only: [:index], controller: :facilitator do
    # TODO: DO these need / before
    # TODO: These probably don't need controller in to:
    get 'teams/:team_id', to: 'facilitator#team', as: 'facilitator_team', on: :collection
    get 'teams/:team_id/progress_form/:release_date', to: 'facilitator#progress_form', as: 'progress_form',
      on: :collection

    get 'marking/:section_id', to: 'facilitator#marking_show', as: 'marking_show', on: :collection

    # AJAX
    post '/update_teams_list' => 'facilitator#update_teams_list', on: :collection
    post '/update_progress_form_response' => 'facilitator#update_progress_form_response', on: :collection
  end

  resources :progress_form, controller: :progress_form do
     # Ajax, TODO: Refactor...?
    post '/add_question' => 'progress_form#add_question', on: :collection
    post '/delete_question' => 'progress_form#delete_question', on: :collection
    post '/save_form' => 'progress_form#save_form', on: :collection
    post '/delete_form' => 'progress_form#delete_form', on: :collection
    post '/show_new' => 'progress_form#show_new', on: :collection
  end

  resources :modules, controller: :course_module do
  end
end
