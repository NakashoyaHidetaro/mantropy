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

  test '票がある状態で個人ランキングの一覧を取得すると漫画ごとのカードが並ぶ' do
    create_votes_of_year2099
    get ranking_series_path(@kojin.name)
    assert_response :success
    assert_select 'div.card.shadow-sm', 2
  end

  test '票がある状態でログインしても個人ランキングの一覧を取得できる' do
    create_votes_of_year2099
    sign_in @userauth
    get ranking_series_path(@kojin.name)
    assert_response :success
    assert_select 'div.card.shadow-sm', 2
  end

  test '個人ランキングのCSVは合計得点の高い順に出力される' do
    create_votes_of_year2099
    get ranking_series_path(@kojin.name, format: :csv)
    assert_response :success

    rows = csv_rows(response.body)
    assert_equal([series(:one).name, series(:two).name], rows.pluck(7))
    assert_equal(%w[1 2], rows.pluck(0))
    # MySerieOne は 1位×2票 → (2+2) + 重複ボーナス3 = 7点、糞補正 -9 で -2点
    assert_equal(%w[7 1], rows.pluck(1))
    assert_equal(%w[-2 1], rows.pluck(2))
  end

  test '糞ランキングのCSVは糞補正後得点の高い順に出力される' do
    create_votes_of_year2099
    get ranking_series_path(@kuso.name, format: :csv)
    assert_response :success

    rows = csv_rows(response.body)
    assert_equal([series(:two).name, series(:one).name], rows.pluck(7))
    assert_equal(%w[1 2], rows.pluck(0))
  end

  test '票がある状態でもJSON・XMLを取得できる' do
    create_votes_of_year2099
    %i[json xml].each do |format|
      get ranking_series_path(@kojin.name, format:)
      assert_response :success
    end
  end

  test '同年度に糞ランキングが無くても個人ランキングの一覧を取得できる' do
    kojin_only = create_kojin_only_ranking
    get ranking_series_path(kojin_only.name)
    assert_response :success
    assert_select 'div.card.shadow-sm', 1
  end

  test '同年度に糞ランキングが無くてもCSV・JSON・XMLを取得できる' do
    kojin_only = create_kojin_only_ranking
    %i[csv json xml].each do |format|
      get ranking_series_path(kojin_only.name, format:)
      assert_response :success
    end
  end

  test '同年度に個人ランキングが無い糞ランキングは集計ページへリダイレクトされる' do
    kuso_only = Ranking.create!(name: '2096年糞ランキング', kind: 'kuso',
                                is_registerable: false, scope_min: 1, scope_max: 2)
    get ranking_series_path(kuso_only.name)
    assert_redirected_to aggregated_ranking_series_path(kuso_only.name)
  end

  private

  # 2099年度に票を入れる（scope_max = 2 なので 1位 = +2点 / 2位 = +1点）。
  # 個人: MySerieOne が 1位×2人 → 4 + 重複ボーナス3 = 7点 / MySerieTwo が 2位×1人 = 1点
  # 糞: MySerieOne が 1位と2位の2人 → (-2-1)*2 - 3 = -9点（MySerieTwo は糞票なし）
  def create_votes_of_year2099
    Rank.create!(rank: 1, ranking: @kojin, user: users(:one), serie: series(:one))
    Rank.create!(rank: 2, ranking: @kojin, user: users(:one), serie: series(:two))
    Rank.create!(rank: 1, ranking: @kojin, user: users(:two), serie: series(:one))
    Rank.create!(rank: 2, ranking: @kuso, user: users(:one), serie: series(:one))
    Rank.create!(rank: 1, ranking: @kuso, user: users(:two), serie: series(:one))
  end

  # 同年度に糞ランキングが存在しない個人ランキングを票つきで作る
  def create_kojin_only_ranking
    ranking = Ranking.create!(name: '2097年個人ランキング', kind: 'kojin',
                              is_registerable: false, scope_min: 1, scope_max: 2)
    Rank.create!(rank: 1, ranking:, user: users(:one), serie: series(:one))
    ranking
  end

  # CSV のヘッダ行と空行を除いたデータ行を配列で返す
  def csv_rows(body)
    body.lines.map(&:chomp).reject(&:empty?).drop(1).map { |line| line.split(',') }
  end
end
