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

  test 'ユーザー詳細画面のcontent_forで設定したタイトルがtitle要素に反映される' do
    user = users(:one)
    get user_path(user.name)
    assert_select 'title', text: "#{user.name} - 漫トロピーWeb"
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
    assert_match rankings(:kojin2015).name, response.body
  end

  test '集計中年度のランキングはゲストには表示されない' do
    start_registering_year2016
    get user_path(users(:one).name)
    assert_response :success
    assert_no_match rankings(:kojin2016).name, response.body
  end

  test 'ログイン済みでも今年の個人ランキング未提出なら集計中年度は表示されない' do
    start_registering_year2016
    sign_in userauths(:two)
    get user_path(users(:one).name)
    assert_response :success
    assert_no_match rankings(:kojin2016).name, response.body
  end

  test '今年の個人ランキングを提出完了したユーザーには集計中年度が表示される' do
    start_registering_year2016
    create_kojin_ranks_of_year2016(users(:two))
    sign_in userauths(:two)
    get user_path(users(:one).name)
    assert_response :success
    assert_match rankings(:kojin2016).name, response.body
  end

  test '本人には集計中年度が表示される' do
    start_registering_year2016
    sign_in userauths(:one)
    get user_path(users(:one).name)
    assert_response :success
    assert_match rankings(:kojin2016).name, response.body
  end

  test '年度ごとの折りたたみUIが出力される' do
    get user_path(users(:one).name)
    assert_response :success
    assert_select 'button.year-toggle[data-bs-target]'
    assert_select 'div.collapse.year-collapse'
  end

  test 'ゲストには内部掲示板の書き込みが表示されない' do
    user = page_owner
    board_post = posts(:one)
    board_post.update!(user: user)
    get user_path(user.name)
    assert_response :success
    assert_no_match board_post.content, response.body
    assert_select "a[href^='/member/']", false
  end

  test 'ログイン時は内部掲示板の書き込みが鍵アイコン付きmemberリンクで表示される' do
    user = page_owner
    board_post = posts(:one)
    board_post.update!(user: user)
    sign_in userauths(:one)
    get user_path(user.name)
    assert_response :success
    assert_match board_post.content, response.body
    assert_select "a[href='#{member_topic_show_path(board_post.topic)}'] i.bi-lock"
  end

  test '漫画へのコメントはゲストにも漫画ページへのリンク付きで表示される' do
    user = page_owner
    topic = Topic.create!(title: nil)
    serie = Serie.create!(name: '漫画コメント用シリーズ', topic: topic)
    comic_post = Post.create!(content: '漫画へのコメント本文', topic: topic, user: user)
    get user_path(user.name)
    assert_response :success
    assert_match comic_post.content, response.body
    assert_select "a[href='#{serie_path(serie)}']"
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
    start_aggregating_year2016
    sign_in userauths(:two)
    get users_path
    assert_response :success
    assert_select "a[href='/users.csv']", false
  end

  test '集計中に未提出のログインユーザーはCSVを取得できない' do
    start_aggregating_year2016
    sign_in userauths(:two)
    get users_path(format: :csv)
    assert_response :not_acceptable
  end

  test '提出完了したログインユーザーにはダウンロードリンクが表示される' do
    start_aggregating_year2016
    create_kojin_ranks_of_year2016(users(:two))
    sign_in userauths(:two)
    get users_path
    assert_response :success
    assert_select "a[href='/users.csv']"
    assert_select "a[href='/users.json']"
  end

  test '提出完了したログインユーザーはCSV/JSONを取得できる' do
    start_aggregating_year2016
    create_kojin_ranks_of_year2016(users(:two))
    sign_in userauths(:two)
    get users_path(format: :csv)
    assert_response :success
    get users_path(format: :json)
    assert_response :success
  end

  test 'ゲストにも旧メンバーがMoreの折りたたみ内に表示される' do
    get users_path
    assert_response :success
    assert_match users(:old_member).name, response.body
    assert_select 'button.old-users-toggle[data-bs-target]'
    assert_select 'div.collapse.old-users-collapse'
  end

  test 'ログインユーザーにも旧メンバーが表示される' do
    sign_in userauths(:one)
    get users_path
    assert_response :success
    assert_match users(:old_member).name, response.body
  end

  private

  # users fixture は name が重複しているため、実際に users#show で表示されるユーザーを取る
  def page_owner
    User.find_by(name: users(:one).name)
  end

  # 2016年を集計中（登録受付中）にし、ページ主のユーザーにも2016年の順位を持たせる
  def start_registering_year2016
    start_aggregating_year2016
    create_kojin_ranks_of_year2016(users(:one))
  end

  # 2016年の個人ランキングを集計中（集計終了日が未来）の状態にする
  def start_aggregating_year2016
    rankings(:kojin2016).update!(aggregation_ends_on: Date.current + 1.month,
                                 published_on: Date.current + 2.months)
  end

  def create_kojin_ranks_of_year2016(user)
    Rank.create!(rank: 1, ranking: rankings(:kojin2016), user: user, serie: series(:one))
    Rank.create!(rank: 2, ranking: rankings(:kojin2016), user: user, serie: series(:two))
  end
end
