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

ActiveRecord::Schema[8.0].define(version: 2025_05_16_063222) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bicycles", force: :cascade do |t|
    t.string "name"
    t.string "brand"
    t.string "model"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "kilometres"
    t.string "terrain"
    t.string "weather"
    t.string "particulate"
    t.index ["user_id"], name: "index_bicycles_on_user_id"
  end

  create_table "brakepads", force: :cascade do |t|
    t.string "brand"
    t.float "kilometres"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bicycle_id", null: false
    t.index ["bicycle_id"], name: "index_brakepads_on_bicycle_id"
  end

  create_table "cassettes", force: :cascade do |t|
    t.string "brand"
    t.float "kilometres"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bicycle_id", null: false
    t.index ["bicycle_id"], name: "index_cassettes_on_bicycle_id"
  end

  create_table "chainrings", force: :cascade do |t|
    t.string "brand"
    t.float "kilometres"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bicycle_id", null: false
    t.index ["bicycle_id"], name: "index_chainrings_on_bicycle_id"
  end

  create_table "chains", force: :cascade do |t|
    t.string "brand"
    t.float "kilometres"
    t.integer "bicycle_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bicycle_id"], name: "index_chains_on_bicycle_id"
  end

  create_table "kilometre_logs", force: :cascade do |t|
    t.string "trackable_type", null: false
    t.bigint "trackable_id", null: false
    t.string "event_type", null: false
    t.float "previous_value", default: 0.0, null: false
    t.float "new_value", default: 0.0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trackable_type", "trackable_id", "created_at"], name: "idx_on_trackable_type_trackable_id_created_at_7a660b97da"
    t.index ["trackable_type", "trackable_id"], name: "index_kilometre_logs_on_trackable"
  end

  create_table "tires", force: :cascade do |t|
    t.string "brand"
    t.float "kilometres"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "bicycle_id", null: false
    t.index ["bicycle_id"], name: "index_tires_on_bicycle_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "jti", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "bicycles", "users"
  add_foreign_key "brakepads", "bicycles"
  add_foreign_key "cassettes", "bicycles"
  add_foreign_key "chainrings", "bicycles"
  add_foreign_key "chains", "bicycles"
  add_foreign_key "tires", "bicycles"
end
