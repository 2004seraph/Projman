Rails.application.routes.draw do
  devise_for :users

  mount EpiCas::Engine, at: "/"

  root "page#index"

  get '/profile', to: 'profile#index'
  get '/settings', to: 'setting#index'

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
  end

  resources :students, only: [:index], controller: :student do
  end

  resources :issues, only: [:index, :create], controller: :issue do
    # AJAX
    post 'project-selected', to: 'issue#update_selection', on: :collection
  end

  resources :facilitators, only: [:index], controller: :facilitator do
    get '/teams/:id/progress_form/:week',
      to: 'facilitator#progress_form', as: 'progress_form',
      on: :collection
    get '/marking/:id',
      to: 'facilitator#marking_show', as: 'marking_show',
      on: :collection
    get '/teams/:id',
      to: 'facilitator#team', as: 'team',
      on: :collection

    # AJAX
    post '/update_teams_list',
      to: 'facilitator#update_teams_list',
      on: :collection
  end

  resources :modules, controller: :course_module do
  end
end
