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

ActiveRecord::Schema[8.1].define(version: 2026_08_23_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "authorideas", id: :serial, force: :cascade do |t|
    t.integer "author_id"
    t.datetime "created_at"
    t.integer "idea"
    t.integer "identify"
    t.datetime "updated_at"
  end

  create_table "authors", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.string "name"
    t.datetime "updated_at"
  end

  create_table "authors_books", id: :serial, force: :cascade do |t|
    t.integer "author_id"
    t.integer "book_id"
    t.datetime "created_at"
    t.string "role"
    t.datetime "updated_at"
  end

  create_table "authors_series", id: :serial, force: :cascade do |t|
    t.integer "author_id"
    t.datetime "created_at"
    t.string "role"
    t.integer "serie_id"
    t.datetime "updated_at"
  end

  create_table "bookaffairs", id: :serial, force: :cascade do |t|
    t.integer "book_id"
    t.datetime "created_at"
    t.integer "event"
    t.datetime "updated_at"
  end

  create_table "bookreals", id: :serial, force: :cascade do |t|
    t.integer "book_id"
    t.datetime "created_at"
    t.text "memo"
    t.datetime "updated_at"
    t.integer "user_id"
  end

  create_table "books", id: :serial, force: :cascade do |t|
    t.string "asin"
    t.datetime "created_at"
    t.string "detailurl"
    t.string "isbn"
    t.boolean "iscomic"
    t.string "kind"
    t.string "label"
    t.string "largeimgurl"
    t.string "mediumimgurl"
    t.string "name"
    t.date "publicationdate"
    t.string "publisher"
    t.string "smallimgurl"
    t.datetime "updated_at"
    t.index ["isbn"], name: "index_books_on_isbn"
    t.index ["iscomic"], name: "index_books_on_iscomic"
    t.index ["name"], name: "index_books_on_name"
  end

  create_table "books_browsenodeids", id: false, force: :cascade do |t|
    t.integer "book_id"
    t.integer "browsenodeid_id"
  end

  create_table "books_series", id: false, force: :cascade do |t|
    t.integer "book_id"
    t.integer "serie_id"
  end

  create_table "browsenodeids", id: :serial, force: :cascade do |t|
    t.bigint "ancestor"
    t.datetime "created_at"
    t.string "name"
    t.bigint "node"
    t.datetime "updated_at"
  end

  create_table "magazines", id: :serial, force: :cascade do |t|
    t.integer "appear"
    t.integer "book_id"
    t.datetime "created_at"
    t.string "name"
    t.string "publisher"
    t.datetime "updated_at"
    t.string "url"
  end

  create_table "magazines_series", id: :serial, force: :cascade do |t|
    t.integer "magazine_id"
    t.string "placed"
    t.integer "serie_id"
  end

  create_table "postfavs", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.integer "post_id"
    t.integer "score"
    t.datetime "updated_at"
    t.integer "user_id"
  end

  create_table "posts", id: :serial, force: :cascade do |t|
    t.text "content"
    t.datetime "created_at"
    t.string "email"
    t.string "name"
    t.integer "order"
    t.integer "topic_id"
    t.datetime "updated_at"
    t.integer "user_id"
  end

  create_table "rankings", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.boolean "is_registerable"
    t.string "kind"
    t.string "name"
    t.integer "scope_max"
    t.integer "scope_min"
    t.datetime "updated_at"
  end

  create_table "ranks", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.integer "rank"
    t.integer "ranking_id"
    t.integer "score"
    t.integer "serie_id"
    t.datetime "updated_at"
    t.integer "user_id"
  end

  create_table "replies", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.integer "post_id"
    t.datetime "updated_at"
    t.integer "user_id"
  end

  create_table "series", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.string "name"
    t.integer "post_id"
    t.string "public_id", null: false
    t.integer "topic_id"
    t.datetime "updated_at"
    t.string "url"
    t.index ["public_id"], name: "index_series_on_public_id", unique: true
  end

  create_table "series_tags", id: false, force: :cascade do |t|
    t.integer "serie_id"
    t.integer "tag_id"
  end

  create_table "site_configs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "path", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["path"], name: "index_site_configs_on_path"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.string "name"
    t.datetime "updated_at"
  end

  create_table "topics", id: :serial, force: :cascade do |t|
    t.integer "appear"
    t.datetime "created_at"
    t.string "title"
    t.datetime "updated_at"
  end

  create_table "transfers", id: :serial, force: :cascade do |t|
    t.integer "bookreal_id"
    t.datetime "created_at"
    t.integer "from"
    t.integer "to"
    t.datetime "updated_at"
    t.integer "user_id"
    t.date "when"
  end

  create_table "userauths", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "current_sign_in_at"
    t.inet "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.inet "last_sign_in_ip"
    t.string "password_salt"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at"
    t.integer "user_id"
    t.index ["email"], name: "index_userauths_on_email", unique: true
    t.index ["reset_password_token"], name: "index_userauths_on_reset_password_token", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.string "entered"
    t.string "joined"
    t.string "mbmail"
    t.string "name"
    t.string "pcmail"
    t.string "privateabout"
    t.string "publicabout"
    t.string "realname"
    t.string "twitter"
    t.datetime "updated_at"
    t.string "url"
  end

  create_table "wikis", id: :serial, force: :cascade do |t|
    t.string "content"
    t.datetime "created_at"
    t.integer "is_private"
    t.string "name"
    t.string "title"
    t.datetime "updated_at"
    t.integer "user_id"
  end
end
