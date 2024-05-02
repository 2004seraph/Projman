Rails.application.routes.draw do
  devise_for :users

  mount EpiCas::Engine, at: "/"

  root "course_project#index"

  get '/profile', to: 'page#profile'
  get '/mailing', to: 'page#mailing'

  resources :projects, controller: :course_project do

    resource :milestone_responses, only: [:create], controller: :milestone_response

    get '/teams', to: 'course_project#teams', on: :member
    post '/new', to: 'course_project#create', on: :collection
    post '/edit', to: 'course_project#update', on: :member

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
    get 'remove_milestone_email', on: :collection
    post 'set_milestone_email_data', on: :collection
    post 'set_milestone_comment', on: :collection
    get 'search_facilitators_student', on: :collection
    get 'search_facilitators_staff', on: :collection
    get 'search_student_name', on: :collection

    post ':group_id/send-chat-message', to: 'course_project#send_chat_message', on: :collection

    resources :progress_form, controller: :progress_form do
      post 'add_question' => 'progress_form#add_question', on: :collection
      post 'add_question' => 'progress_form#add_question', on: :member 
      post 'delete_question' => 'progress_form#delete_question', on: :collection
      post 'delete_question' => 'progress_form#delete_question', on: :member
      post 'save_form' => 'progress_form#save_form', on: :collection
      post 'save_form' => 'progress_form#save_form', on: :member
      post 'delete_form' => 'progress_form#delete_form', on: :collection
      post 'delete_form' => 'progress_form#delete_form', on: :member
      post 'change_title' => 'progress_form#change_title', on: :member
      post 'change_title' => 'progress_form#change_title', on: :collection

      post 'show_new' => 'progress_form#show_new', on: :collection

    end

    resources :mark_scheme, controller: :mark_scheme do
      post 'add_section' => 'mark_scheme#add_section', on: :collection
      post 'add_section' => 'mark_scheme#add_section', on: :member
      post 'delete_section' => 'mark_scheme#delete_section', on: :collection
      post 'delete_section' => 'mark_scheme#delete_section', on: :member
      post 'save' => 'mark_scheme#save', on: :collection
      post 'save' => 'mark_scheme#save', on: :member
  
      post 'add_to_facilitators_selection' => "mark_scheme#add_to_facilitators_selection", on: :collection
      post "add_facilitators_selection" => "mark_scheme#add_facilitators_selection", on: :collection
      post 'clear_facilitators_selection' => "mark_scheme#clear_facilitators_selection", on: :collection
      post "remove_from_facilitator_selection" => "mark_scheme#remove_from_facilitator_selection", on: :collection
      post "remove_facilitator_from_section" => "mark_scheme#remove_facilitator_from_section", on: :collection
      post "get_assignable_teams" => "mark_scheme#get_assignable_teams", on: :collection
      post "assign_teams" => "mark_scheme#assign_teams", on: :collection
      post "auto_assign_teams" => "mark_scheme#auto_assign_teams", on: :collection
      get 'search_facilitators' => "mark_scheme#search_facilitators", on: :collection

      post "show_new", on: :collection
  
    end

  end

  resources :students, only: [:index], controller: :student do
    post '/update_selection' => 'student#update_selection', on: :collection
  end

  resources :issues, only: [:index, :create], controller: :issue do
    # AJAX
    post 'update-selection', to: 'issue#update_selection', on: :collection
    post 'issue-response', to: 'issue#issue_response', on: :collection
    post 'update-status', to: 'issue#update_status', on: :collection
  end

  resources :facilitators, only: [:index], controller: :facilitator do
    get 'teams/:team_id', to: 'facilitator#team', as: 'facilitator_team', on: :collection
    get 'teams/:team_id/progress_form/:milestone_id', to: 'facilitator#progress_form', as: 'progress_form',
      on: :collection

    get 'marking/:milestone_id/section/:section_index', to: 'facilitator#marking_show', as: 'marking_show', on: :collection

    # AJAX
    post '/update_teams_list' => 'facilitator#update_teams_list', on: :collection
    post '/update_progress_form_response' => 'facilitator#update_progress_form_response', on: :collection
    post '/update_marking' => 'facilitator#update_marking', on: :collection
  end

  



  resources :modules, controller: :course_module do
  end
end
