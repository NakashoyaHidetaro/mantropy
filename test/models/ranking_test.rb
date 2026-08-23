require 'test_helper'

class RankingTest < ActiveSupport::TestCase
  # --- name / to_param ---

  test 'name は年度と種別名を連結した表示名になる' do
    assert_equal '2015年漫トロ個人ランキング', rankings(:kojin2015).name
    assert_equal '2015年漫トロ個人クソランキング', rankings(:kuso2015).name
  end

  test 'name は全体集計ランキングでも種別ごとの表示名になる' do
    zentai = build_ranking(2020, :zentai)
    zentaikuso = build_ranking(2020, :zentaikuso)

    assert_equal '2020年漫トロピー漫画ランキング', zentai.name
    assert_equal '2020年漫トロピークソ漫画ランキング', zentaikuso.name
  end

  test 'to_param は 年度-スラッグ 形式になる' do
    assert_equal '2015-all', rankings(:kojin2015).to_param
    assert_equal '2015-kuso', rankings(:kuso2015).to_param
    assert_equal '2020-zentai', build_ranking(2020, :zentai).to_param
    assert_equal '2020-zentai-kuso', build_ranking(2020, :zentaikuso).to_param
  end

  # --- find_by_slug ---

  test 'find_by_slug は to_param の値から元のランキングを引ける' do
    [rankings(:kojin2015), rankings(:kuso2015), rankings(:kojin2016)].each do |ranking|
      assert_equal ranking, Ranking.find_by_slug(ranking.to_param)
    end
  end

  test 'find_by_slug はハイフンを含むスラッグも解釈できる' do
    zentaikuso = create_ranking(2020, :zentaikuso)

    assert_equal zentaikuso, Ranking.find_by_slug('2020-zentai-kuso')
  end

  test 'find_by_slug は該当するランキングが無ければ nil を返す' do
    assert_nil Ranking.find_by_slug('1999-all')
  end

  test 'find_by_slug は不正な形式なら nil を返す' do
    ['', nil, '2015', 'all', '2015-', '-all', 'abcd-all', '2015-unknown', '15-all'].each do |param|
      assert_nil Ranking.find_by_slug(param), "#{param.inspect} で nil が返らなかった"
    end
  end

  # --- registerable? / finished? / published? ---

  test 'registerable? は集計終了日当日までは true になる' do
    ranking = rankings(:kojin2015)

    travel_to Date.new(2015, 11, 19) do
      assert_predicate ranking, :registerable?
    end
    travel_to Date.new(2015, 11, 20) do
      assert_predicate ranking, :registerable?
    end
    travel_to Date.new(2015, 11, 21) do
      assert_not_predicate ranking, :registerable?
    end
  end

  test 'finished? は registerable? の反対になる' do
    ranking = rankings(:kojin2015)

    travel_to Date.new(2015, 11, 20) do
      assert_not_predicate ranking, :finished?
    end
    travel_to Date.new(2015, 11, 21) do
      assert_predicate ranking, :finished?
    end
  end

  test 'published? は一般公開日当日から true になる' do
    ranking = rankings(:kojin2015)

    travel_to Date.new(2015, 12, 30) do
      assert_not_predicate ranking, :published?
    end
    travel_to Date.new(2015, 12, 31) do
      assert_predicate ranking, :published?
    end
    travel_to Date.new(2016, 1, 1) do
      assert_predicate ranking, :published?
    end
  end

  # --- scope ---

  test 'registerable スコープは集計終了日当日のランキングを含む' do
    travel_to Date.new(2015, 11, 20) do
      assert_includes Ranking.registerable, rankings(:kojin2015)
      assert_not_includes Ranking.finished, rankings(:kojin2015)
    end
  end

  test 'finished スコープは集計終了日の翌日からランキングを含む' do
    travel_to Date.new(2015, 11, 21) do
      assert_includes Ranking.finished, rankings(:kojin2015)
      assert_not_includes Ranking.registerable, rankings(:kojin2015)
    end
  end

  test 'registerable と finished は互いに排他になる' do
    travel_to Date.new(2016, 6, 1) do
      assert_empty(Ranking.registerable.to_a & Ranking.finished.to_a)
      assert_equal Ranking.count, (Ranking.registerable.to_a + Ranking.finished.to_a).uniq.size
    end
  end

  test 'aggregated スコープは全体集計ランキングのみを返す' do
    zentai = create_ranking(2020, :zentai)
    zentaikuso = create_ranking(2020, :zentaikuso)

    result = Ranking.aggregated.to_a
    assert_includes result, zentai
    assert_includes result, zentaikuso
    assert_not_includes result, rankings(:kojin2015)
    assert_not_includes result, rankings(:kuso2015)
  end

  # --- バリデーション ---

  test '年度・集計終了日・一般公開日は必須' do
    ranking = Ranking.new(kind: :kojin)

    assert_not ranking.valid?
    assert_includes ranking.errors.attribute_names, :year
    assert_includes ranking.errors.attribute_names, :aggregation_ends_on
    assert_includes ranking.errors.attribute_names, :published_on
  end

  test '同じ年度・同じ種別のランキングは重複して作れない' do
    duplicated = build_ranking(2015, :kojin)

    assert_not duplicated.valid?
    assert_includes duplicated.errors.attribute_names, :year
  end

  test '同じ年度でも種別が違えば作れる' do
    assert_predicate build_ranking(2015, :zentai), :valid?
  end

  private

  def build_ranking(year, kind)
    Ranking.new(year:, kind:, scope_min: 1, scope_max: 2,
                aggregation_ends_on: Date.new(year, 11, 20), published_on: Date.new(year, 12, 31))
  end

  def create_ranking(year, kind)
    build_ranking(year, kind).tap(&:save!)
  end
end
