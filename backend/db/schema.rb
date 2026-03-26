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

ActiveRecord::Schema[7.2].define(version: 2026_03_26_000002) do
  create_table "ipl_players", force: :cascade do |t|
    t.string "name", null: false
    t.integer "ipl_team_id", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ipl_team_id"], name: "index_ipl_players_on_ipl_team_id"
  end

  create_table "ipl_teams", force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name", null: false
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "match_entries", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "match_id", null: false
    t.integer "captain_id"
    t.integer "vice_captain_id"
    t.decimal "total_points", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["captain_id"], name: "index_match_entries_on_captain_id"
    t.index ["match_id"], name: "index_match_entries_on_match_id"
    t.index ["user_id", "match_id"], name: "index_match_entries_on_user_id_and_match_id", unique: true
    t.index ["user_id"], name: "index_match_entries_on_user_id"
    t.index ["vice_captain_id"], name: "index_match_entries_on_vice_captain_id"
  end

  create_table "matches", force: :cascade do |t|
    t.integer "team1_id", null: false
    t.integer "team2_id", null: false
    t.datetime "match_date", null: false
    t.string "venue"
    t.string "status", default: "upcoming", null: false
    t.integer "match_number"
    t.string "api_match_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cricapi_match_id"
    t.datetime "last_synced_at"
    t.boolean "auto_sync", default: false
    t.index ["cricapi_match_id"], name: "index_matches_on_cricapi_match_id"
    t.index ["team1_id"], name: "index_matches_on_team1_id"
    t.index ["team2_id"], name: "index_matches_on_team2_id"
  end

  create_table "player_match_performances", force: :cascade do |t|
    t.integer "match_id", null: false
    t.integer "ipl_player_id", null: false
    t.integer "runs_scored", default: 0
    t.integer "balls_faced", default: 0
    t.integer "fours", default: 0
    t.integer "sixes", default: 0
    t.boolean "is_duck", default: false
    t.boolean "did_bat", default: false
    t.decimal "overs_bowled", precision: 4, scale: 1, default: "0.0"
    t.integer "maidens", default: 0
    t.integer "runs_conceded", default: 0
    t.integer "wickets", default: 0
    t.integer "lbw_bowled_count", default: 0
    t.integer "catches", default: 0
    t.integer "stumpings", default: 0
    t.integer "direct_run_outs", default: 0
    t.integer "indirect_run_outs", default: 0
    t.decimal "fantasy_points", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ipl_player_id"], name: "index_player_match_performances_on_ipl_player_id"
    t.index ["match_id", "ipl_player_id"], name: "idx_perf_match_player", unique: true
    t.index ["match_id"], name: "index_player_match_performances_on_match_id"
  end

  create_table "team_selections", force: :cascade do |t|
    t.integer "match_entry_id", null: false
    t.integer "ipl_player_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ipl_player_id"], name: "index_team_selections_on_ipl_player_id"
    t.index ["match_entry_id", "ipl_player_id"], name: "index_team_selections_on_match_entry_id_and_ipl_player_id", unique: true
    t.index ["match_entry_id"], name: "index_team_selections_on_match_entry_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.index ["name"], name: "index_users_on_name", unique: true
  end

  add_foreign_key "ipl_players", "ipl_teams"
  add_foreign_key "match_entries", "ipl_players", column: "captain_id"
  add_foreign_key "match_entries", "ipl_players", column: "vice_captain_id"
  add_foreign_key "match_entries", "matches"
  add_foreign_key "match_entries", "users"
  add_foreign_key "matches", "ipl_teams", column: "team1_id"
  add_foreign_key "matches", "ipl_teams", column: "team2_id"
  add_foreign_key "player_match_performances", "ipl_players"
  add_foreign_key "player_match_performances", "matches"
  add_foreign_key "team_selections", "ipl_players"
  add_foreign_key "team_selections", "match_entries"
end
