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

ActiveRecord::Schema[8.0].define(version: 2025_02_08_194524) do
  create_table "bicycles", force: :cascade do |t|
    t.string "name"
    t.string "brand"
    t.string "model"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "kilometres"
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
  end

  add_foreign_key "bicycles", "users"
  add_foreign_key "brakepads", "bicycles"
  add_foreign_key "cassettes", "bicycles"
  add_foreign_key "chainrings", "bicycles"
  add_foreign_key "chains", "bicycles"
  add_foreign_key "tires", "bicycles"
end
