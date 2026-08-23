require 'test_helper'

class Member::HomesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    sign_in @userauth
  end

  test 'ホーム画面を取得できる' do
    get member_root_path
    assert_response :success
  end

  test '集計データ欄に全てのランキングのダウンロードリンクが列挙される' do
    ranking = rankings(:kojin2015)

    get member_root_path

    assert_response :success
    assert_select 'a[href=?]', aggregated_ranking_series_path(ranking)
    assert_select 'a[href=?]', ranking_series_path(ranking, format: :csv)
    assert_select 'a[href=?]', ranking_series_path(ranking, format: :json)
    assert_select 'a[href=?]', ranking_series_path(ranking, format: :xml)
    assert_select 'a[href=?]', users_path(format: :csv)
    assert_select 'a[href=?]', users_path(format: :json)
  end

  test 'ログインしていない場合はログイン画面にリダイレクトされる' do
    sign_out @userauth
    get member_root_path
    assert_redirected_to new_userauth_session_path
  end
end
