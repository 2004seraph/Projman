# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_04_17_140249) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "group_event_type", ["generic", "milestone", "chat", "issue"]
  create_enum "milestone_milestone_type", ["for_each_student", "for_each_staff", "for_each_team"]
  create_enum "milestone_system_type", ["teammate_preference_deadline", "project_preference_deadline", "project_deadline", "mark_scheme"]
  create_enum "project_status", ["draft", "preparation", "review", "live", "completed", "archived"]
  create_enum "project_team_allocation", ["random", "preference_form_based"]
  create_enum "student_fee_status", ["home", "overseas"]

  create_table "assigned_facilitators", force: :cascade do |t|
    t.bigint "student_id"
    t.bigint "staff_id"
    t.bigint "course_project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_project_id"], name: "index_assigned_facilitators_on_course_project_id"
    t.index ["staff_id"], name: "index_assigned_facilitators_on_staff_id"
    t.index ["student_id", "staff_id", "course_project_id"], name: "module_assignment", unique: true
    t.index ["student_id"], name: "index_assigned_facilitators_on_student_id"
  end

  create_table "course_modules", force: :cascade do |t|
    t.citext "code", null: false
    t.string "name", limit: 64, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "staff_id"
    t.index ["code"], name: "index_course_modules_on_code", unique: true
    t.index ["staff_id"], name: "index_course_modules_on_staff_id"
  end

  create_table "course_modules_students", id: false, force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "course_module_id", null: false
    t.index ["course_module_id"], name: "index_course_modules_students_on_course_module_id"
    t.index ["student_id", "course_module_id"], name: "modules_students_index", unique: true
    t.index ["student_id"], name: "index_course_modules_students_on_student_id"
  end

  create_table "course_projects", force: :cascade do |t|
    t.bigint "course_module_id", null: false
    t.string "name", default: "Unnamed Project", null: false
    t.enum "status", default: "draft", null: false, enum_type: "project_status"
    t.integer "team_size", null: false
    t.enum "team_allocation", enum_type: "project_team_allocation"
    t.integer "preferred_teammates", default: 0
    t.integer "avoided_teammates", default: 0
    t.boolean "teams_from_project_choice", default: false, null: false
    t.json "markscheme_json", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_module_id"], name: "index_course_projects_on_course_module_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "event_responses", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "staff_id"
    t.bigint "student_id"
    t.json "json_data", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_responses_on_event_id"
    t.index ["staff_id"], name: "index_event_responses_on_staff_id"
    t.index ["student_id"], name: "index_event_responses_on_student_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.enum "event_type", null: false, enum_type: "group_event_type"
    t.boolean "completed", default: false
    t.json "json_data", default: "{}", null: false
    t.bigint "student_id"
    t.bigint "staff_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_events_on_group_id"
    t.index ["staff_id"], name: "index_events_on_staff_id"
    t.index ["student_id"], name: "index_events_on_student_id"
  end

  create_table "groups", force: :cascade do |t|
    t.bigint "course_project_id", null: false
    t.string "name", default: "My Group"
    t.json "profile", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "assigned_facilitator_id"
    t.bigint "subproject_id"
    t.index ["assigned_facilitator_id"], name: "index_groups_on_assigned_facilitator_id"
    t.index ["course_project_id"], name: "index_groups_on_course_project_id"
    t.index ["subproject_id"], name: "index_groups_on_subproject_id"
  end

  create_table "groups_students", id: false, force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "group_id", null: false
    t.index ["student_id", "group_id"], name: "index_groups_students_on_student_id_and_group_id"
  end

  create_table "milestone_responses", force: :cascade do |t|
    t.bigint "milestone_id", null: false
    t.bigint "student_id"
    t.bigint "staff_id"
    t.json "json_data", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["milestone_id"], name: "index_milestone_responses_on_milestone_id"
    t.index ["staff_id"], name: "index_milestone_responses_on_staff_id"
    t.index ["student_id"], name: "index_milestone_responses_on_student_id"
  end

  create_table "milestones", force: :cascade do |t|
    t.bigint "course_project_id", null: false
    t.enum "milestone_type", null: false, enum_type: "milestone_milestone_type"
    t.datetime "deadline", precision: nil, null: false
    t.json "json_data", default: "{}", null: false
    t.boolean "user_generated", default: false, null: false
    t.enum "system_type", enum_type: "milestone_system_type"
    t.boolean "executed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_project_id"], name: "index_milestones_on_course_project_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cas_ticket"
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "staffs", force: :cascade do |t|
    t.citext "email", null: false
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.index ["email"], name: "index_staffs_on_email", unique: true
  end

  create_table "students", force: :cascade do |t|
    t.string "preferred_name", limit: 24, null: false
    t.string "forename", limit: 24, null: false
    t.string "middle_names", limit: 64, default: ""
    t.string "surname", limit: 24, default: ""
    t.citext "username", null: false
    t.string "title", limit: 4, null: false
    t.enum "fee_status", null: false, enum_type: "student_fee_status"
    t.string "ucard_number", limit: 9, null: false
    t.citext "email", null: false
    t.string "personal_tutor", limit: 64, default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "uid"
    t.string "mail"
    t.string "ou"
    t.string "dn"
    t.string "sn"
    t.string "givenname"
    t.string "account_type"
    t.index ["email"], name: "index_students_on_email"
    t.index ["ucard_number"], name: "index_students_on_ucard_number", unique: true
    t.index ["username"], name: "index_students_on_username", unique: true
  end

  create_table "subprojects", force: :cascade do |t|
    t.bigint "course_project_id", null: false
    t.string "name", default: "Unnamed project choice", null: false
    t.json "json_data", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_project_id"], name: "index_subprojects_on_course_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.citext "email", default: "", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "uid"
    t.string "mail"
    t.string "ou"
    t.string "dn"
    t.string "sn"
    t.string "givenname"
    t.string "account_type"
    t.index ["email"], name: "index_users_on_email"
    t.index ["username"], name: "index_users_on_username"
  end

  add_foreign_key "assigned_facilitators", "course_projects"
  add_foreign_key "course_modules", "staffs"
  add_foreign_key "course_modules_students", "course_modules", on_delete: :cascade
  add_foreign_key "course_modules_students", "students", on_delete: :cascade
  add_foreign_key "course_projects", "course_modules"
  add_foreign_key "event_responses", "events"
  add_foreign_key "events", "groups"
  add_foreign_key "groups", "assigned_facilitators", on_delete: :nullify
  add_foreign_key "groups", "course_projects"
  add_foreign_key "groups", "subprojects"
  add_foreign_key "groups_students", "groups", on_delete: :cascade
  add_foreign_key "groups_students", "students", on_delete: :cascade
  add_foreign_key "milestone_responses", "milestones"
  add_foreign_key "milestones", "course_projects"
  add_foreign_key "subprojects", "course_projects"
end
