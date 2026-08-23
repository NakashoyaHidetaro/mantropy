require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  test 'ユーザー一覧画面を取得できる' do
    get users_path
    assert_response :success
  end

  test 'ユーザー詳細画面を取得できる' do
    user = users(:one)
    get user_path(user.name)
    assert_response :success
  end

  test '存在しないユーザーの場合はリダイレクトされる' do
    get user_path('nonexistent_user')
    assert_redirected_to users_path
  end

  test 'ゲストにはmember専用リンクが表示されない' do
    user = users(:one)
    get user_path(user.name)
    assert_response :success
    assert_select "a[href^='/member/']", false
  end

  test '過去年度のランキングはゲストにも表示される' do
    start_registering_year2016
    get user_path(users(:one).name)
    assert_response :success
    assert_match '2015年個人ランキング', response.body
  end

  test '集計中年度のランキングはゲストには表示されない' do
    start_registering_year2016
    get user_path(users(:one).name)
    assert_response :success
    assert_no_match '2016年個人ランキング', response.body
  end

  test 'ログイン済みでも今年の個人ランキング未提出なら集計中年度は表示されない' do
    start_registering_year2016
    sign_in userauths(:two)
    get user_path(users(:one).name)
    assert_response :success
    assert_no_match '2016年個人ランキング', response.body
  end

  test '今年の個人ランキングを提出完了したユーザーには集計中年度が表示される' do
    start_registering_year2016
    create_kojin_ranks_of_year2016(users(:two))
    sign_in userauths(:two)
    get user_path(users(:one).name)
    assert_response :success
    assert_match '2016年個人ランキング', response.body
  end

  test '本人には集計中年度が表示される' do
    start_registering_year2016
    sign_in userauths(:one)
    get user_path(users(:one).name)
    assert_response :success
    assert_match '2016年個人ランキング', response.body
  end

  test '年度ごとの折りたたみUIが出力される' do
    get user_path(users(:one).name)
    assert_response :success
    assert_select 'button.year-toggle[data-bs-target]'
    assert_select 'div.collapse.year-collapse'
  end

  test 'ゲストにはCSV/JSONダウンロードリンクが表示されない' do
    get users_path
    assert_response :success
    assert_select "a[href='/users.csv']", false
    assert_select "a[href='/users.json']", false
  end

  test 'ゲストはCSVを取得できない' do
    get users_path(format: :csv)
    assert_response :not_acceptable
  end

  test '集計中に未提出のログインユーザーにはダウンロードリンクが表示されない' do
    rankings(:kojin2016).update!(is_registerable: true)
    sign_in userauths(:two)
    get users_path
    assert_response :success
    assert_select "a[href='/users.csv']", false
  end

  test '集計中に未提出のログインユーザーはCSVを取得できない' do
    rankings(:kojin2016).update!(is_registerable: true)
    sign_in userauths(:two)
    get users_path(format: :csv)
    assert_response :not_acceptable
  end

  test '提出完了したログインユーザーにはダウンロードリンクが表示される' do
    rankings(:kojin2016).update!(is_registerable: true)
    create_kojin_ranks_of_year2016(users(:two))
    sign_in userauths(:two)
    get users_path
    assert_response :success
    assert_select "a[href='/users.csv']"
    assert_select "a[href='/users.json']"
  end

  test '提出完了したログインユーザーはCSV/JSONを取得できる' do
    rankings(:kojin2016).update!(is_registerable: true)
    create_kojin_ranks_of_year2016(users(:two))
    sign_in userauths(:two)
    get users_path(format: :csv)
    assert_response :success
    get users_path(format: :json)
    assert_response :success
  end

  private

  # 2016年を集計中（登録受付中）にし、ページ主のユーザーにも2016年の順位を持たせる
  def start_registering_year2016
    rankings(:kojin2016).update!(is_registerable: true)
    create_kojin_ranks_of_year2016(users(:one))
  end

  def create_kojin_ranks_of_year2016(user)
    Rank.create!(rank: 1, ranking: rankings(:kojin2016), user: user, serie: series(:one))
    Rank.create!(rank: 2, ranking: rankings(:kojin2016), user: user, serie: series(:two))
  end
end
