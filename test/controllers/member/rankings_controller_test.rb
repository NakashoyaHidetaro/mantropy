require 'test_helper'

class Member::RankingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    @ranking = rankings(:kojin2015)
    sign_in @userauth
  end

  test 'index画面を取得できる（認証あり）' do
    get member_rankings_path, headers: basic_auth_header
    assert_response :success
  end

  test 'ログインしていない場合はログイン画面にリダイレクトされる' do
    sign_out @userauth
    get member_rankings_path
    assert_redirected_to new_userauth_session_path
  end

  test 'BASIC認証が無い場合は認証を要求される' do
    get member_rankings_path
    assert_response :unauthorized
  end

  test '年度・種別・公開日を指定してランキングを作成できる' do
    assert_difference 'Ranking.count', 1 do
      post member_rankings_path, headers: basic_auth_header, params: { ranking: new_ranking_params }
    end
    assert_redirected_to member_rankings_path

    created = Ranking.find_by(year: 2020, kind: :kojin)
    assert_equal Date.new(2020, 11, 20), created.aggregation_ends_on
    assert_equal Date.new(2020, 12, 31), created.published_on
  end

  test '既存ランキングの集計終了日・一般公開日を更新できる' do
    patch member_ranking_path(@ranking), headers: basic_auth_header,
                                         params: { ranking: new_ranking_params.merge(year: @ranking.year,
                                                                                     kind: @ranking.kind) }
    assert_redirected_to member_rankings_path
    assert_equal Date.new(2020, 11, 20), @ranking.reload.aggregation_ends_on
  end

  test '不正なパラメータでの作成は422を返しエラーが表示される' do
    assert_no_difference 'Ranking.count' do
      post member_rankings_path, headers: basic_auth_header,
                                 params: { ranking: new_ranking_params.merge(scope_min: '', scope_max: '') }
    end
    assert_response :unprocessable_entity
    assert_match 'alert-danger', response.body
  end

  test '不正なパラメータでの更新は422を返し既存データは変更されない' do
    patch member_ranking_path(@ranking), headers: basic_auth_header,
                                         params: { ranking: new_ranking_params.merge(year: @ranking.year,
                                                                                     kind: @ranking.kind,
                                                                                     scope_min: '') }
    assert_response :unprocessable_entity
    assert_match 'alert-danger', response.body
    assert_equal Date.new(2015, 11, 20), @ranking.reload.aggregation_ends_on
  end

  test '位最小値が位最大値より大きい場合は作成できない' do
    assert_no_difference 'Ranking.count' do
      post member_rankings_path, headers: basic_auth_header,
                                 params: { ranking: new_ranking_params.merge(scope_min: 10, scope_max: 1) }
    end
    assert_response :unprocessable_entity
  end

  private

  def new_ranking_params
    { year: 2020, kind: 'kojin', scope_min: 1, scope_max: 10,
      aggregation_ends_on: '2020-11-20', published_on: '2020-12-31' }
  end

  def basic_auth_header
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials(
      ENV['DIGEST_USER'] || 'test',
      ENV['DIGEST_PASS'] || 'test'
    )
    { 'HTTP_AUTHORIZATION' => credentials }
  end
end
