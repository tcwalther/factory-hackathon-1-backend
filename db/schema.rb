# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150703194330) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "itineraries", force: :cascade do |t|
    t.string   "origin_address"
    t.string   "destination_address"
    t.string   "departure_airport"
    t.string   "arrival_airport"
    t.string   "flight_number"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.float    "origin_latitude"
    t.float    "origin_longitude"
    t.float    "destination_latitude"
    t.float    "destination_longitude"
  end

  create_table "locations", force: :cascade do |t|
    t.string   "type"
    t.datetime "time"
    t.string   "address"
    t.string   "airport"
    t.string   "gate"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "routes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "price_cents"
    t.string   "currency"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "routes", ["user_id"], name: "index_routes_on_user_id", using: :btree

  create_table "steps", force: :cascade do |t|
    t.integer  "route_id"
    t.string   "type"
    t.integer  "departure_id"
    t.integer  "arrival_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "steps", ["route_id"], name: "index_steps_on_route_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "routes", "users"
  add_foreign_key "steps", "routes"
end
