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

ActiveRecord::Schema[7.0].define(version: 2024_03_17_231948) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "group_event_type", ["generic", "milestone", "chat", "issue"]
  create_enum "milestone_type", ["individual", "staff", "group", "live", "final"]
  create_enum "project_choice_allocation", ["random", "individual_preference", "team_preference"]
  create_enum "project_status", ["draft", "student_preference", "student_preference_review", "team_preference", "team_preference_review", "live", "completed", "archived"]
  create_enum "project_team_allocation", ["random", "preference_based"]
  create_enum "student_fee_status", ["home", "overseas"]

  create_table "assigned_facilitators", force: :cascade do |t|
    t.bigint "student_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id"], name: "index_assigned_facilitators_on_student_id"
  end

  create_table "course_modules", force: :cascade do |t|
    t.string "name", limit: 32, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "course_modules_students", id: false, force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "course_module_id", null: false
    t.index ["student_id", "course_module_id"], name: "modules_students_index"
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

  create_table "events", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.enum "type", null: false, enum_type: "group_event_type"
    t.json "json_data", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_events_on_group_id"
  end

  create_table "groups", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "name", default: "My Group"
    t.json "profile", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "assigned_facilitator_id"
    t.index ["assigned_facilitator_id"], name: "index_groups_on_assigned_facilitator_id"
    t.index ["project_id"], name: "index_groups_on_project_id"
  end

  create_table "groups_students", id: false, force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "group_id", null: false
    t.index ["student_id", "group_id"], name: "index_groups_students_on_student_id_and_group_id"
  end

  create_table "milestone_responses", force: :cascade do |t|
    t.bigint "milestone_id", null: false
    t.json "json_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["milestone_id"], name: "index_milestone_responses_on_milestone_id"
  end

  create_table "milestones", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.enum "type", null: false, enum_type: "milestone_type"
    t.date "deadline", null: false
    t.json "json_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_milestones_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "course_module_id", null: false
    t.string "name", null: false
    t.enum "status", null: false, enum_type: "project_status"
    t.integer "team_size", null: false
    t.enum "team_allocation", null: false, enum_type: "project_team_allocation"
    t.integer "preferred_teammates", default: 0
    t.integer "avoided_teammates", default: 0
    t.enum "project_allocation", null: false, enum_type: "project_choice_allocation"
    t.json "project_choices_json", default: "{}"
    t.json "markscheme_json", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_module_id"], name: "index_projects_on_course_module_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "students", force: :cascade do |t|
    t.string "preferred_name", limit: 24, null: false
    t.string "forename", limit: 24, null: false
    t.string "middle_names", limit: 64, default: ""
    t.string "surname", limit: 24, default: ""
    t.string "username", limit: 16, null: false
    t.string "title", limit: 4, null: false
    t.enum "fee_status", null: false, enum_type: "student_fee_status"
    t.string "ucard_number", limit: 9, null: false
    t.string "email", limit: 254, null: false
    t.string "personal_tutor", limit: 64, default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "assigned_facilitators", "students"
  add_foreign_key "course_modules_students", "course_modules", on_delete: :cascade
  add_foreign_key "course_modules_students", "students", on_delete: :cascade
  add_foreign_key "events", "groups"
  add_foreign_key "groups", "assigned_facilitators"
  add_foreign_key "groups", "projects"
  add_foreign_key "groups_students", "groups", on_delete: :cascade
  add_foreign_key "groups_students", "students", on_delete: :cascade
  add_foreign_key "milestone_responses", "milestones"
  add_foreign_key "milestones", "projects"
  add_foreign_key "projects", "course_modules"
end
