require 'test_helper'

class YearlyRankingTest < ActiveSupport::TestCase
  test 'of_year は指定年度のランキングのみを返す' do
    result = Ranking.of_year(2015).to_a

    assert_equal [rankings(:kojin2015), rankings(:kuso2015)].map(&:id).sort, result.map(&:id).sort
    assert_not_includes result, rankings(:kojin2016)
  end

  test 'of_year は年度に文字列を渡しても西暦として扱う' do
    assert_equal Ranking.of_year(2015).to_a.map(&:id).sort, Ranking.of_year('2015').to_a.map(&:id).sort
  end

  test 'of_year は該当年度が無ければ空になる' do
    assert_empty Ranking.of_year(1999).to_a
  end

  test 'of_year は kind で絞り込める' do
    assert_equal [rankings(:kuso2015)], Ranking.of_year(2015, kind: 'kuso').to_a
    assert_equal [rankings(:kojin2015)], Ranking.of_year(2015, kind: 'kojin').to_a
  end

  test 'of_year は kind に配列を渡すと複数種別を返す' do
    zentai2015 = Ranking.create!(year: 2015, kind: 'zentai', scope_min: 1, scope_max: 2,
                                 aggregation_ends_on: Date.new(2015, 11, 20), published_on: Date.new(2015, 12, 31))

    result = Ranking.of_year(2015, kind: %w[kojin kuso]).to_a
    assert_includes result, rankings(:kuso2015)
    assert_includes result, rankings(:kojin2015)
    assert_not_includes result, zentai2015
  end

  test 'same_year_as は基準ランキングと同じ年度のランキングを返す' do
    result = Ranking.same_year_as(rankings(:kojin2015)).to_a

    assert_includes result, rankings(:kuso2015)
    assert_includes result, rankings(:kojin2015)
    assert_not_includes result, rankings(:kojin2016)
  end

  test 'same_year_as も kind で絞り込める' do
    assert_equal [rankings(:kuso2015)], Ranking.same_year_as(rankings(:kojin2015), kind: 'kuso').to_a
  end
end
