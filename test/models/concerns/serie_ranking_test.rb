require 'test_helper'

class SerieRankingTest < ActiveSupport::TestCase
  # fixture の 2015年度は以下の構成になっている（kojin2015 / kuso2015 とも scope_max = 2）。
  #
  # 【個人（kojin2015）】1位 = +2点 / 2位 = +1点、2人目以降の投票者1人につき +3点
  #   series(:one)     … one:1位, two:1位, three:2位 → (2+2+1) + 3*2 = 11点 / 得票2件超の3件 / 最高1位
  #   series(:voted_a) … three:1位, four:1位         → (2+2)   + 3*1 =  7点 / 2件 / 最高1位
  #   series(:two)     … one:2位, four:2位           → (1+1)   + 3*1 =  5点 / 2件 / 最高2位
  #
  # 【糞（kuso2015）】1位 = -2点 / 2位 = -1点、合計に ×2、2人目以降の投票者1人につき -3点
  #   series(:one)     … two:1位, three:2位 → (-2-1)*2 + (-3) = -9点 / 2件
  #   series(:voted_a) … two:2位, three:1位 → (-1-2)*2 + (-3) = -9点 / 2件
  #   series(:two)     … 投票なし                            →   0点 / 0件
  #
  # 【糞補正後】series(:two) = 5点, series(:one) = 2点, series(:voted_a) = -2点

  def kojin
    rankings(:kojin2015)
  end

  def kuso
    rankings(:kuso2015)
  end

  # rank_info から指定キーの値を漫画名ごとに引けるハッシュにする
  def info_by_name(series, key)
    series.to_h { |serie| [serie.name, serie.rank_info[key]] }
  end

  # --- ranking_pair ---

  test 'ranking_pair は個人ランキングなら自身と同年度の糞ランキングを返す' do
    assert_equal [kojin, kuso], SerieRanking.ranking_pair(kojin)
  end

  test 'ranking_pair は糞ランキングなら同年度の個人ランキングと自身を返す' do
    assert_equal [kojin, kuso], SerieRanking.ranking_pair(kuso)
  end

  test 'ranking_pair はランキングが nil なら nil を返す' do
    assert_nil SerieRanking.ranking_pair(nil)
  end

  test 'ranking_pair は個人・クソ以外のkindでは nil を返す' do
    assert_nil SerieRanking.ranking_pair(create_ranking(2015, :zentai))
    assert_nil SerieRanking.ranking_pair(create_ranking(2015, :zentaikuso))
  end

  test 'ranking_pair は同年度に対となるランキングが無ければ相方が nil になる' do
    # kojin2016 と同年度のクソランキングは存在しない
    assert_equal [rankings(:kojin2016), nil], SerieRanking.ranking_pair(rankings(:kojin2016))
  end

  test 'ranking_pair はクソランキングだけの年度ならプラス側が nil になる' do
    lonely_kuso = create_ranking(2020, :kuso)
    assert_equal [nil, lonely_kuso], SerieRanking.ranking_pair(lonely_kuso)
  end

  # --- restriction_notice ---

  test 'restriction_notice は集計中なら誰も閲覧できない' do
    travel_to Date.new(2015, 11, 20) do
      assert_equal 'ランキングは集計中なので誰も見れないよ', SerieRanking.restriction_notice(kojin, nil)
      assert_equal 'ランキングは集計中なので誰も見れないよ', SerieRanking.restriction_notice(kojin, users(:one))
    end
  end

  test 'restriction_notice は集計終了後から一般公開日前はメンバーだけ閲覧できる' do
    travel_to Date.new(2015, 11, 21) do
      assert_equal 'ランキングは集計中なのでメンバーだけが見れるよ', SerieRanking.restriction_notice(kojin, nil)
      assert_nil SerieRanking.restriction_notice(kojin, users(:one))
    end
  end

  test 'restriction_notice は一般公開日当日から誰でも閲覧できる' do
    travel_to Date.new(2015, 12, 31) do
      assert_nil SerieRanking.restriction_notice(kojin, nil)
      assert_nil SerieRanking.restriction_notice(kojin, users(:one))
    end
  end

  test 'restriction_notice は一般公開日を過ぎていれば誰でも閲覧できる' do
    assert_nil SerieRanking.restriction_notice(kojin, nil)
  end

  # --- aggregate: プラス点の計算 ---

  test 'aggregate は満点から順位を引いた点数と重複ボーナスを合計する' do
    marks = info_by_name(SerieRanking.aggregate(kojin, kuso), :sum_of_mark)

    assert_equal 11, marks['MySerieOne'] # 3人が投票（+2,+2,+1）+ 重複ボーナス3点×2人
    assert_equal 7, marks['集計テスト漫画A'] # 2人が1位（+2,+2）+ 重複ボーナス3点×1人
    assert_equal 5, marks['MySerieTwo'] # 2人が2位（+1,+1）+ 重複ボーナス3点×1人
  end

  test 'aggregate は個人ランキングの得票数を count_rank に入れる' do
    counts = info_by_name(SerieRanking.aggregate(kojin, kuso), :count_rank)

    assert_equal 3, counts['MySerieOne']
    assert_equal 2, counts['集計テスト漫画A']
    assert_equal 2, counts['MySerieTwo']
  end

  test 'aggregate は個人ランキングに票が無い漫画を結果に含めない' do
    series = SerieRanking.aggregate(kojin, kuso)

    assert_not_includes series.map(&:name), '集計テスト漫画Z'
    assert_equal 3, series.size
  end

  test 'aggregate は単独投票なら重複ボーナスが付かない' do
    ranking = create_ranking(2050, :kojin, scope_max: 3)
    serie = create_serie('単独投票漫画')
    Rank.create!(rank: 2, ranking:, user: users(:one), serie:)

    # 満点(3+1) - 2位 = 2点、重複ボーナスなし
    assert_equal 2, SerieRanking.aggregate(ranking, nil).first.rank_info[:sum_of_mark]
  end

  # --- aggregate: 糞補正 ---

  test 'aggregate は糞ランキングの点数に倍率と重複ペナルティを掛けて補正する' do
    with_kuso = info_by_name(SerieRanking.aggregate(kojin, kuso), :sum_of_mark_with_kuso)

    assert_equal 2, with_kuso['MySerieOne'] # 11 - 9
    assert_equal(-2, with_kuso['集計テスト漫画A']) # 7 - 9
    assert_equal 5, with_kuso['MySerieTwo'] # 5 - 0（糞票なし）
  end

  test 'aggregate は糞ランキングの得票数を count_kuso に入れ、票が無ければ0にする' do
    counts = info_by_name(SerieRanking.aggregate(kojin, kuso), :count_kuso)

    assert_equal 2, counts['MySerieOne']
    assert_equal 2, counts['集計テスト漫画A']
    assert_equal 0, counts['MySerieTwo']
  end

  test 'aggregate は糞票が無い漫画の補正を0にする' do
    series = SerieRanking.aggregate(kojin, kuso)
    serie_two = series.find { |s| s.name == 'MySerieTwo' }

    assert_equal serie_two.rank_info[:sum_of_mark], serie_two.rank_info[:sum_of_mark_with_kuso]
  end

  test 'aggregate は糞補正が常に0以下になる' do
    SerieRanking.aggregate(kojin, kuso).each do |serie|
      assert_operator serie.rank_info[:sum_of_mark_with_kuso], :<=, serie.rank_info[:sum_of_mark]
    end
  end

  test 'aggregate は ranking_minus が nil でも例外にならず補正0として扱う' do
    series = assert_nothing_raised { SerieRanking.aggregate(kojin, nil) }

    assert_equal 3, series.size
    series.each do |serie|
      assert_equal serie.rank_info[:sum_of_mark], serie.rank_info[:sum_of_mark_with_kuso]
      assert_equal 0, serie.rank_info[:count_kuso]
    end
  end

  test 'aggregate はプラス側が nil なら空配列を返す' do
    assert_equal [], SerieRanking.aggregate(nil, kuso)
  end

  # --- aggregate: count_post ---

  test 'aggregate はランキング作成後に投稿されたコメントだけを count_post に数える' do
    counts = info_by_name(SerieRanking.aggregate(kojin, kuso), :count_post)

    # 集計テスト漫画A のトピックには作成後1件・作成前1件のコメントがある
    assert_equal 1, counts['集計テスト漫画A']
  end

  test 'aggregate はトピックが無い漫画の count_post を0にする' do
    counts = info_by_name(SerieRanking.aggregate(kojin, kuso), :count_post)

    assert_equal 0, counts['MySerieOne']
    assert_equal 0, counts['MySerieTwo']
  end

  test 'aggregate はランキング作成後にコメントが増えれば count_post も増える' do
    Post.create!(content: '追加コメント', topic: topics(:serie_a_topic), user: users(:one))
    counts = info_by_name(SerieRanking.aggregate(kojin, kuso), :count_post)

    assert_equal 2, counts['集計テスト漫画A']
  end

  # --- aggregate: ソート順 ---

  test 'aggregate は sort_by_kuso が false なら合計得点の降順に並ぶ' do
    names = SerieRanking.aggregate(kojin, kuso, sort_by_kuso: false).map(&:name)

    assert_equal %w[MySerieOne 集計テスト漫画A MySerieTwo], names
  end

  test 'aggregate は sort_by_kuso が true なら糞補正後得点の降順に並ぶ' do
    names = SerieRanking.aggregate(kojin, kuso, sort_by_kuso: true).map(&:name)

    assert_equal %w[MySerieTwo MySerieOne 集計テスト漫画A], names
  end

  test 'aggregate は合計得点が同点なら得票数の多い順・最高順位の高い順に並ぶ' do
    ranking = create_ranking(2051, :kojin, scope_max: 5)
    # 9点・2票・最高2位
    high = create_serie('同点漫画_最高2位')
    Rank.create!(rank: 2, ranking:, user: users(:one), serie: high)
    Rank.create!(rank: 4, ranking:, user: users(:two), serie: high)
    # 9点・2票・最高3位
    low = create_serie('同点漫画_最高3位')
    Rank.create!(rank: 3, ranking:, user: users(:three), serie: low)
    Rank.create!(rank: 3, ranking:, user: users(:four), serie: low)
    # 5点・2票（得票数が同じでも点数が低いので後ろ）
    few = create_serie('同点漫画_5点2票')
    Rank.create!(rank: 5, ranking:, user: users(:one), serie: few)
    Rank.create!(rank: 5, ranking:, user: users(:two), serie: few)
    # 5点・1票（同点なら得票数の少ない方が後ろ）
    single = create_serie('同点漫画_5点1票')
    Rank.create!(rank: 1, ranking:, user: users(:three), serie: single)

    names = SerieRanking.aggregate(ranking, nil).map(&:name)
    assert_equal %w[同点漫画_最高2位 同点漫画_最高3位 同点漫画_5点2票 同点漫画_5点1票], names
  end

  # --- aggregate: rank_info の中身 ---

  test 'aggregate は rank_info の値をすべて Integer で返す' do
    SerieRanking.aggregate(kojin, kuso).each do |serie|
      %i[rank sum_of_mark sum_of_mark_with_kuso count_rank count_kuso count_post].each do |key|
        assert_kind_of Integer, serie.rank_info[key], "#{serie.name} の #{key} が Integer ではない"
      end
    end
  end

  test 'aggregate は rank_info に順位を付与する' do
    series = SerieRanking.aggregate(kojin, kuso)

    assert_equal([1, 2, 3], series.map { |s| s.rank_info[:rank] })
  end

  test 'aggregate は糞ソート時にも順位を付与する' do
    series = SerieRanking.aggregate(kojin, kuso, sort_by_kuso: true)

    assert_equal([1, 2, 3], series.map { |s| s.rank_info[:rank] })
  end

  test 'aggregate は集計値がすべて等しい漫画に同じ順位を付ける' do
    ranking = create_ranking(2052, :kojin)
    first = create_serie('完全同点漫画1')
    second = create_serie('完全同点漫画2')
    behind = create_serie('下位漫画')
    Rank.create!(rank: 1, ranking:, user: users(:one), serie: first)
    Rank.create!(rank: 1, ranking:, user: users(:two), serie: second)
    Rank.create!(rank: 2, ranking:, user: users(:three), serie: behind)

    series = SerieRanking.aggregate(ranking, nil)
    assert_equal([1, 1, 3], series.map { |s| s.rank_info[:rank] })
    assert_equal '下位漫画', series.last.name
  end

  # --- aggregated_series ---

  test 'aggregated_series はランキングの順位順に漫画を返す' do
    ranking = create_ranking(2053, :zentai, scope_max: 3)
    third = create_serie('集計済み3位')
    first = create_serie('集計済み1位')
    second = create_serie('集計済み2位')
    Rank.create!(rank: 3, ranking:, user: users(:one), serie: third)
    Rank.create!(rank: 1, ranking:, user: users(:one), serie: first)
    Rank.create!(rank: 2, ranking:, user: users(:one), serie: second)

    assert_equal [first, second, third], SerieRanking.aggregated_series(ranking).to_a
  end

  test 'aggregated_series は他のランキングの票を含めない' do
    series = SerieRanking.aggregated_series(rankings(:kojin2016))

    assert_empty series.to_a
  end

  # --- same_year_rankings_by_kind ---

  test 'same_year_rankings_by_kind は同年度のランキングを kind をキーにした Hash で返す' do
    zentai = create_ranking(2015, :zentai)
    result = SerieRanking.same_year_rankings_by_kind(kojin)

    assert_equal({ 'kojin' => kojin, 'kuso' => kuso, 'zentai' => zentai }, result)
  end

  test 'same_year_rankings_by_kind は他の年度のランキングを含めない' do
    result = SerieRanking.same_year_rankings_by_kind(rankings(:kojin2016))

    assert_equal({ 'kojin' => rankings(:kojin2016) }, result)
  end

  test 'same_year_rankings_by_kind はランキングが nil なら空の Hash を返す' do
    assert_empty SerieRanking.same_year_rankings_by_kind(nil)
  end

  private

  def create_serie(name)
    Serie.create!(name:)
  end

  def create_ranking(year, kind, scope_max: 2)
    Ranking.create!(year:, kind:, scope_min: 1, scope_max:,
                    aggregation_ends_on: Date.new(year, 11, 20), published_on: Date.new(year, 12, 31))
  end
end
