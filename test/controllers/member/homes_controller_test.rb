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
    ranking = Ranking.create!(name: '2099年個人ランキング', kind: 'kojin',
                              is_registerable: false, scope_min: 1, scope_max: 2)

    get member_root_path

    assert_response :success
    assert_select 'a[href=?]', aggregated_ranking_series_path(ranking.name)
    assert_select 'a[href=?]', ranking_series_path(ranking.name, format: :csv)
    assert_select 'a[href=?]', ranking_series_path(ranking.name, format: :json)
    assert_select 'a[href=?]', ranking_series_path(ranking.name, format: :xml)
    assert_select 'a[href=?]', users_path(format: :csv)
    assert_select 'a[href=?]', users_path(format: :json)
  end

  test 'ログインしていない場合はログイン画面にリダイレクトされる' do
    sign_out @userauth
    get member_root_path
    assert_redirected_to new_userauth_session_path
  end
end
