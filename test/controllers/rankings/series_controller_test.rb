require 'test_helper'

class Rankings::SeriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    @kojin = create_published_ranking(year: 2013, kind: :kojin)
    @kuso = create_published_ranking(year: 2013, kind: :kuso)
  end

  test '存在しないslugの場合はランキング一覧へリダイレクトされる' do
    get ranking_series_path('9999-nonexistent')
    assert_redirected_to rankings_path
    assert flash[:notice].present?
  end

  test '全体集計ランキングの一覧は集計ページへリダイレクトされる' do
    zentai = create_published_ranking(year: 2013, kind: :zentai)
    get ranking_series_path(zentai)
    assert_response :redirect
    assert_redirected_to aggregated_ranking_series_path(zentai)
  end

  test 'ランキング別集計済みシリーズ一覧画面を取得できる' do
    zentai = create_published_ranking(year: 2013, kind: :zentai)
    get aggregated_ranking_series_path(zentai)
    assert_response :success
  end

  test '全体集計ページの順位・得点は同年度の全体集計ランキングのrankから表示される' do
    year2017 = create_aggregated_year(2017)
    get aggregated_ranking_series_path(year2017[:zentai])
    assert_response :success

    # zentai の rank/score が「順位」「得点」に、zentaikuso の rank/score が「糞修正」に出る
    assert_select 'span.badge', text: '順位: 1'
    assert_select 'span.badge', text: '得点（重複修正）: 111'
    assert_select 'span.badge', text: '糞修正順位: 2'
    assert_select 'span.badge', text: '糞修正得点: 222'
    # 重複数は同年度の個人ランキングの票数（users one / three の2件）
    assert_select 'span.badge', text: '重複数: 2'
  end

  test '全体集計ページの投票者リストは同年度の個人・糞ランキングの票から表示される' do
    year2017 = create_aggregated_year(2017)
    get aggregated_ranking_series_path(year2017[:zentai])
    assert_response :success

    assert_select 'a[href=?]', user_path(users(:three).name), text: "#{users(:three).name} (2位)"
    assert_select 'a[href=?]', user_path(users(:four).name), text: "#{users(:four).name} (糞1位)"
  end

  test '全体集計ページには他の年度のランキングの票や得点は表示されない' do
    year2017 = create_aggregated_year(2017)
    create_aggregated_year(2018)
    get aggregated_ranking_series_path(year2017[:zentai])
    assert_response :success

    # 2018年度の得点（zentai の score + 1000）や投票者は現れない
    assert_select 'span.badge', text: '得点（重複修正）: 1111', count: 0
    assert_select 'span.badge', text: '糞修正得点: 1222', count: 0
    assert_select 'a[href=?]', user_path(users(:three).name), count: 1
  end

  test '全体集計ページでは個人ランキングへ投票済みの漫画に自分の投票が明示される' do
    year2017 = create_aggregated_year(2017)
    sign_in @userauth
    get aggregated_ranking_series_path(year2017[:zentai])
    assert_response :success
    assert_select 'div.card-header', 1
  end

  test '全体集計ページは同年度に個人・糞ランキングが無くても取得できる' do
    zentai = create_published_ranking(year: 2019, kind: :zentai)
    Rank.create!(rank: 1, score: 10, ranking: zentai, user: users(:one), serie: series(:one))
    get aggregated_ranking_series_path(zentai)
    assert_response :success
    assert_select 'span.badge', text: '重複数: 0'
  end

  test 'ランキング別シリーズ一覧をCSV・JSON・XMLで取得できる' do
    %i[csv json xml].each do |format|
      get ranking_series_path(@kojin, format:)
      assert_response :success
    end
  end

  test '同じ年度に集計済みランキングがある場合はその集計ページへのリンクが表示される' do
    aggregated = create_published_ranking(year: 2013, kind: :zentai)
    get ranking_series_path(@kojin)
    assert_response :success
    assert_select 'a[href=?]', aggregated_ranking_series_path(aggregated)
  end

  test '同じ年度に集計済みランキングが無い場合は集計ページへのリンクは表示されない' do
    get ranking_series_path(@kojin)
    assert_response :success
    assert_select 'a[href=?]', aggregated_ranking_series_path(@kojin), false
    assert_select 'a[href=?]', aggregated_ranking_series_path(@kuso), false
  end

  test '他の年度の集計済みランキングへのリンクは表示されない' do
    other_year = create_published_ranking(year: 2010, kind: :zentai)
    get ranking_series_path(@kojin)
    assert_response :success
    assert_select 'a[href=?]', aggregated_ranking_series_path(other_year), false
  end

  test '集計中（集計終了日まで）のランキングはゲストもメンバーも閲覧できない' do
    travel_to Date.new(2015, 11, 1) do
      get ranking_series_path(rankings(:kojin2015))
      assert_redirected_to rankings_path
      assert flash[:notice].present?

      sign_in @userauth
      get ranking_series_path(rankings(:kojin2015))
      assert_redirected_to rankings_path
      assert flash[:notice].present?
    end
  end

  test '集計終了後・一般公開前はメンバーだけが閲覧できる' do
    travel_to Date.new(2015, 12, 1) do
      get ranking_series_path(rankings(:kojin2015))
      assert_redirected_to rankings_path
      assert flash[:notice].present?

      sign_in @userauth
      get ranking_series_path(rankings(:kojin2015))
      assert_response :success
    end
  end

  test '一般公開日以降はゲストもダウンロードリンク付きで閲覧できる' do
    get ranking_series_path(rankings(:kojin2015))
    assert_response :success
    assert_select 'a[href=?]', ranking_series_path(rankings(:kojin2015), format: :csv)
    assert_select 'a[href=?]', ranking_series_path(rankings(:kojin2015), format: :json)
    assert_select 'a[href=?]', ranking_series_path(rankings(:kojin2015), format: :xml)
  end

  test '票がある状態で個人ランキングの一覧を取得すると漫画ごとのカードが並ぶ' do
    create_votes_of_year2013
    get ranking_series_path(@kojin)
    assert_response :success
    assert_select 'div.card.shadow-sm', 2
  end

  test '票がある状態でログインしても個人ランキングの一覧を取得できる' do
    create_votes_of_year2013
    sign_in @userauth
    get ranking_series_path(@kojin)
    assert_response :success
    assert_select 'div.card.shadow-sm', 2
  end

  test '個人ランキングのCSVは合計得点の高い順に出力される' do
    create_votes_of_year2013
    get ranking_series_path(@kojin, format: :csv)
    assert_response :success

    rows = csv_rows(response.body)
    assert_equal([series(:one).name, series(:two).name], rows.pluck(7))
    assert_equal(%w[1 2], rows.pluck(0))
    # MySerieOne は 1位×2票 → (2+2) + 重複ボーナス3 = 7点、糞補正 -9 で -2点
    assert_equal(%w[7 1], rows.pluck(1))
    assert_equal(%w[-2 1], rows.pluck(2))
  end

  test '糞ランキングのCSVは糞補正後得点の高い順に出力される' do
    create_votes_of_year2013
    get ranking_series_path(@kuso, format: :csv)
    assert_response :success

    rows = csv_rows(response.body)
    assert_equal([series(:two).name, series(:one).name], rows.pluck(7))
    assert_equal(%w[1 2], rows.pluck(0))
  end

  test '票がある状態でもJSON・XMLを取得できる' do
    create_votes_of_year2013
    %i[json xml].each do |format|
      get ranking_series_path(@kojin, format:)
      assert_response :success
    end
  end

  test '同年度に糞ランキングが無くても個人ランキングの一覧を取得できる' do
    kojin_only = create_kojin_only_ranking
    get ranking_series_path(kojin_only)
    assert_response :success
    assert_select 'div.card.shadow-sm', 1
  end

  test '同年度に糞ランキングが無くてもCSV・JSON・XMLを取得できる' do
    kojin_only = create_kojin_only_ranking
    %i[csv json xml].each do |format|
      get ranking_series_path(kojin_only, format:)
      assert_response :success
    end
  end

  test '同年度に個人ランキングが無い糞ランキングは集計ページへリダイレクトされる' do
    kuso_only = create_published_ranking(year: 2011, kind: :kuso)
    get ranking_series_path(kuso_only)
    assert_redirected_to aggregated_ranking_series_path(kuso_only)
  end

  private

  # 一般公開済み（集計終了日・一般公開日ともに過去）のランキングを作る
  def create_published_ranking(year:, kind:)
    Ranking.create!(year:, kind:, scope_min: 1, scope_max: 2,
                    aggregation_ends_on: Date.new(year, 11, 20),
                    published_on: Date.new(year, 12, 31))
  end

  # 指定年度に kojin / kuso / zentai / zentaikuso の4種のランキングを作り、series(:one) に票を入れる。
  # zentai は 1位・111点、zentaikuso は 2位・222点（年度ごとに1000点ずつずらして区別できるようにする）。
  # 個人票は users(:one)（1位）と users(:three)（2位）、糞票は users(:four)（1位）。
  def create_aggregated_year(year)
    rankings = %i[kojin kuso zentai zentaikuso].index_with { |kind| create_published_ranking(year:, kind:) }
    offset = (year - 2017) * 1000
    Rank.create!(rank: 1, score: 111 + offset, ranking: rankings[:zentai], user: users(:one), serie: series(:one))
    Rank.create!(rank: 2, score: 222 + offset, ranking: rankings[:zentaikuso], user: users(:one), serie: series(:one))
    Rank.create!(rank: 1, ranking: rankings[:kojin], user: users(:one), serie: series(:one))
    Rank.create!(rank: 2, ranking: rankings[:kojin], user: users(:three), serie: series(:one))
    Rank.create!(rank: 1, ranking: rankings[:kuso], user: users(:four), serie: series(:one))
    rankings
  end

  # 2013年度に票を入れる（scope_max = 2 なので 1位 = +2点 / 2位 = +1点）。
  # 個人: MySerieOne が 1位×2人 → 4 + 重複ボーナス3 = 7点 / MySerieTwo が 2位×1人 = 1点
  # 糞: MySerieOne が 1位と2位の2人 → (-2-1)*2 - 3 = -9点（MySerieTwo は糞票なし）
  def create_votes_of_year2013
    Rank.create!(rank: 1, ranking: @kojin, user: users(:one), serie: series(:one))
    Rank.create!(rank: 2, ranking: @kojin, user: users(:one), serie: series(:two))
    Rank.create!(rank: 1, ranking: @kojin, user: users(:two), serie: series(:one))
    Rank.create!(rank: 2, ranking: @kuso, user: users(:one), serie: series(:one))
    Rank.create!(rank: 1, ranking: @kuso, user: users(:two), serie: series(:one))
  end

  # 同年度に糞ランキングが存在しない個人ランキングを票つきで作る
  def create_kojin_only_ranking
    ranking = create_published_ranking(year: 2012, kind: :kojin)
    Rank.create!(rank: 1, ranking:, user: users(:one), serie: series(:one))
    ranking
  end

  # CSV のヘッダ行と空行を除いたデータ行を配列で返す
  def csv_rows(body)
    body.lines.map(&:chomp).reject(&:empty?).drop(1).map { |line| line.split(',') }
  end
end
