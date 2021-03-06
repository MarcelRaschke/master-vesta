# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181209171928) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "buildings", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "clip_memberships", force: :cascade do |t|
    t.bigint "clip_id"
    t.bigint "group_id"
    t.boolean "confirmed", default: false, null: false
    t.index ["clip_id"], name: "index_clip_memberships_on_clip_id"
    t.index ["group_id"], name: "index_clip_memberships_on_group_id"
  end

  create_table "clips", force: :cascade do |t|
    t.bigint "draw_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draw_id"], name: "index_clips_on_draw_id"
  end

  create_table "colleges", force: :cascade do |t|
    t.string "name", null: false
    t.string "dean", null: false
    t.string "admin_email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "floor_plan_url"
    t.text "student_info_text"
    t.string "subdomain", null: false
    t.index ["name"], name: "index_colleges_on_name"
    t.index ["subdomain"], name: "index_colleges_on_subdomain", unique: true
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
    t.string "tenant"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "draw_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "draw_id"
    t.bigint "old_draw_id"
    t.integer "intent", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draw_id"], name: "index_draw_memberships_on_draw_id"
    t.index ["old_draw_id"], name: "index_draw_memberships_on_old_draw_id"
    t.index ["user_id"], name: "index_draw_memberships_on_user_id"
  end

  create_table "draw_suites", force: :cascade do |t|
    t.bigint "draw_id", null: false
    t.bigint "suite_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draw_id"], name: "index_draw_suites_on_draw_id"
    t.index ["suite_id"], name: "index_draw_suites_on_suite_id"
  end

  create_table "draws", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.date "intent_deadline"
    t.integer "locked_sizes", default: [], null: false, array: true
    t.boolean "intent_locked", default: false, null: false
    t.datetime "last_email_sent"
    t.integer "email_type"
    t.date "locking_deadline"
    t.integer "suite_selection_mode", default: 0, null: false
    t.boolean "allow_clipping", default: false, null: false
    t.boolean "restrict_clipping_group_size", default: false, null: false
    t.boolean "active", default: true, null: false
  end

  create_table "groups", force: :cascade do |t|
    t.integer "size", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.integer "draw_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "memberships_count", default: 0, null: false
    t.integer "transfers", default: 0, null: false
    t.bigint "lottery_assignment_id"
    t.bigint "leader_draw_membership_id"
    t.index ["draw_id"], name: "index_groups_on_draw_id"
    t.index ["leader_draw_membership_id"], name: "index_groups_on_leader_draw_membership_id", unique: true
    t.index ["lottery_assignment_id"], name: "index_groups_on_lottery_assignment_id"
  end

  create_table "lottery_assignments", force: :cascade do |t|
    t.bigint "draw_id"
    t.integer "number", null: false
    t.boolean "selected", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "clip_id"
    t.index ["clip_id"], name: "index_lottery_assignments_on_clip_id"
    t.index ["draw_id", "number"], name: "index_lottery_assignments_on_draw_id_and_number", unique: true
    t.index ["draw_id"], name: "index_lottery_assignments_on_draw_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.boolean "locked", default: false, null: false
    t.bigint "draw_membership_id"
    t.index ["draw_membership_id"], name: "index_memberships_on_draw_membership_id"
    t.index ["group_id"], name: "index_memberships_on_group_id"
  end

  create_table "room_assignments", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "draw_membership_id"
    t.index ["draw_membership_id"], name: "index_room_assignments_on_draw_membership_id"
    t.index ["room_id"], name: "index_room_assignments_on_room_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.integer "suite_id"
    t.string "number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "beds", default: 0, null: false
    t.string "original_suite", default: "", null: false
    t.index ["suite_id"], name: "index_rooms_on_suite_id"
  end

  create_table "suite_assignments", force: :cascade do |t|
    t.bigint "suite_id", null: false
    t.bigint "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_suite_assignments_on_group_id", unique: true
    t.index ["suite_id"], name: "index_suite_assignments_on_suite_id"
  end

  create_table "suites", force: :cascade do |t|
    t.integer "building_id"
    t.string "number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "size", default: 0, null: false
    t.boolean "medical", default: false
    t.index ["building_id"], name: "index_suites_on_building_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "username"
    t.integer "class_year"
    t.datetime "tos_accepted"
    t.bigint "college_id"
    t.index ["college_id"], name: "index_users_on_college_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "clip_memberships", "clips"
  add_foreign_key "clip_memberships", "groups"
  add_foreign_key "draw_memberships", "draws"
  add_foreign_key "draw_memberships", "draws", column: "old_draw_id"
  add_foreign_key "draw_memberships", "shared.users", column: "user_id"
  add_foreign_key "groups", "draw_memberships", column: "leader_draw_membership_id"
  add_foreign_key "groups", "lottery_assignments"
  add_foreign_key "lottery_assignments", "clips"
  add_foreign_key "lottery_assignments", "draws"
  add_foreign_key "memberships", "draw_memberships"
  add_foreign_key "room_assignments", "draw_memberships"
  add_foreign_key "room_assignments", "rooms"
  add_foreign_key "suite_assignments", "groups"
  add_foreign_key "suite_assignments", "suites"
  add_foreign_key "users", "colleges"

  create_view "lottery_base_views",  sql_definition: <<-SQL
      SELECT clips.draw_id,
      clips.id AS clip_id,
      NULL::bigint AS group_id
     FROM clips
  UNION
   SELECT groups.draw_id,
      NULL::bigint AS clip_id,
      groups.id AS group_id
     FROM (groups groups
       LEFT JOIN clip_memberships ON ((groups.id = clip_memberships.group_id)))
    WHERE (clip_memberships.confirmed IS NOT TRUE);
  SQL

end
