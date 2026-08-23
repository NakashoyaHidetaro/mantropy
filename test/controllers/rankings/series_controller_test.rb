require 'test_helper'

class Rankings::SeriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    @kojin = Ranking.create!(name: '2099年個人ランキング', kind: 'kojin',
                             is_registerable: false, scope_min: 1, scope_max: 2)
    @kuso = Ranking.create!(name: '2099年糞ランキング', kind: 'kuso',
                            is_registerable: false, scope_min: 1, scope_max: 2)
  end

  test 'ランキング別シリーズ一覧画面はkindが未設定の場合aggregatedにリダイレクトされる' do
    ranking = rankings(:one)
    get ranking_series_path(ranking)
    assert_response :redirect
    assert_redirected_to aggregated_ranking_series_path(ranking.name)
  end

  test 'ランキング別集計済みシリーズ一覧画面を取得できる' do
    ranking = rankings(:one)
    get aggregated_ranking_series_path(ranking)
    assert_response :success
  end

  test 'ランキング別シリーズ一覧をCSV・JSON・XMLで取得できる' do
    %i[csv json xml].each do |format|
      get ranking_series_path(@kojin.name, format:)
      assert_response :success
    end
  end

  test '同じ年度に集計済みランキングがある場合はその集計ページへのリンクが表示される' do
    aggregated = Ranking.create!(name: '2099年総合ランキング', kind: 'total',
                                 is_registerable: false, scope_min: 1, scope_max: 2)
    get ranking_series_path(@kojin.name)
    assert_response :success
    assert_select 'a[href=?]', aggregated_ranking_series_path(aggregated.name)
  end

  test '同じ年度に集計済みランキングが無い場合は集計ページへのリンクは表示されない' do
    get ranking_series_path(@kojin.name)
    assert_response :success
    assert_select 'a[href=?]', aggregated_ranking_series_path(@kojin.name), false
    assert_select 'a[href=?]', aggregated_ranking_series_path(@kuso.name), false
  end

  test '他の年度の集計済みランキングへのリンクは表示されない' do
    other_year = Ranking.create!(name: '2098年総合ランキング', kind: 'total',
                                 is_registerable: false, scope_min: 1, scope_max: 2)
    get ranking_series_path(@kojin.name)
    assert_response :success
    assert_select 'a[href=?]', aggregated_ranking_series_path(other_year.name), false
  end

  test '集計中にメンバー限定公開の場合ゲストはリダイレクトされメンバーだけがダウンロードリンクを見られる' do
    SiteConfig.create!(path: 'ranking_now_share_with', name: '公開範囲', value: 'members')

    get ranking_series_path(@kojin.name)
    assert_redirected_to rankings_path

    sign_in @userauth
    get ranking_series_path(@kojin.name)
    assert_response :success
    assert_select 'a[href=?]', ranking_series_path(@kojin.name, format: :csv)
    assert_select 'a[href=?]', ranking_series_path(@kojin.name, format: :json)
    assert_select 'a[href=?]', ranking_series_path(@kojin.name, format: :xml)
  end
end
