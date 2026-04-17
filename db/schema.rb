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

ActiveRecord::Schema[8.1].define(version: 2026_04_17_115500) do
  create_table "answers", force: :cascade do |t|
    t.string "body", null: false
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "question_id", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["question_id"], name: "index_answers_one_correct_per_question", unique: true, where: "correct = 1"
  end

  create_table "games", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "current_question_id"
    t.datetime "question_opened_at"
    t.integer "quiz_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_games_on_code", unique: true
    t.index ["current_question_id"], name: "index_games_on_current_question_id"
    t.index ["quiz_id"], name: "index_games_on_quiz_id"
  end

  create_table "participants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["game_id", "user_id"], name: "index_participants_on_game_id_and_user_id", unique: true
    t.index ["game_id"], name: "index_participants_on_game_id"
    t.index ["user_id"], name: "index_participants_on_user_id"
  end

  create_table "questions", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.integer "quiz_id", null: false
    t.integer "time_limit_seconds", default: 15, null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_questions_on_quiz_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "creator_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_quizzes_on_creator_id"
  end

  create_table "references", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "question_id", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["question_id"], name: "index_references_on_question_id"
  end

  create_table "responses", force: :cascade do |t|
    t.integer "answer_id", null: false
    t.datetime "created_at", null: false
    t.integer "participant_id", null: false
    t.integer "question_id", null: false
    t.datetime "responded_at", null: false
    t.integer "score", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "index_responses_on_answer_id"
    t.index ["participant_id", "question_id"], name: "index_responses_on_participant_id_and_question_id", unique: true
    t.index ["participant_id"], name: "index_responses_on_participant_id"
    t.index ["question_id"], name: "index_responses_on_question_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address"
    t.string "name", null: false
    t.string "password_digest"
    t.string "session_token", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["session_token"], name: "index_users_on_session_token", unique: true
  end

  add_foreign_key "answers", "questions"
  add_foreign_key "games", "questions", column: "current_question_id"
  add_foreign_key "games", "quizzes"
  add_foreign_key "participants", "games"
  add_foreign_key "participants", "users"
  add_foreign_key "questions", "quizzes"
  add_foreign_key "quizzes", "users", column: "creator_id", on_delete: :nullify
  add_foreign_key "references", "questions"
  add_foreign_key "responses", "answers"
  add_foreign_key "responses", "participants"
  add_foreign_key "responses", "questions"
  add_foreign_key "sessions", "users"
end
