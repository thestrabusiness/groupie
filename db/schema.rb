# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_07_05_185217) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name", null: false
    t.string "image_url"
  end

  create_table "message_caches", force: :cascade do |t|
    t.datetime "started_at", default: -> { "now()" }, null: false
    t.datetime "ended_at"
    t.bigint "group_id", null: false
    t.bigint "started_by_id", null: false
    t.index ["group_id"], name: "index_message_caches_on_group_id"
    t.index ["started_by_id"], name: "index_message_caches_on_started_by_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.string "user_id", null: false
    t.boolean "system", default: false, null: false
    t.string "avatar_url"
    t.text "text"
    t.text "favorited_by", default: [], null: false, array: true
    t.integer "favorites_count", default: 0, null: false
    t.jsonb "attachments", default: {}, null: false
    t.json "raw_message", default: {}, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "sender_name"
    t.index ["group_id"], name: "index_messages_on_group_id"
    t.index ["system"], name: "index_messages_on_system"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "image_url", null: false
    t.string "access_token", null: false
    t.string "encrypted_password", limit: 128
    t.string "confirmation_token", limit: 128
    t.string "remember_token", limit: 128
    t.text "group_ids", default: [], null: false, array: true
    t.index ["email"], name: "index_users_on_email"
    t.index ["remember_token"], name: "index_users_on_remember_token"
  end

  add_foreign_key "message_caches", "groups"
  add_foreign_key "message_caches", "users", column: "started_by_id"
  add_foreign_key "messages", "groups"
end
