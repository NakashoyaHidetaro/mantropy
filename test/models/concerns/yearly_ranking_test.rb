require 'test_helper'

class YearlyRankingTest < ActiveSupport::TestCase
  test 'year が name の先頭4文字（西暦）を返す' do
    assert_equal '2015', rankings(:kojin2015).year
  end

  test '別の年度のランキングでも正しい西暦を返す' do
    assert_equal '2016', rankings(:kojin2016).year
  end

  test 'name が nil の場合は year も nil を返す' do
    assert_nil Ranking.new(name: nil).year
  end

  test 'name が4文字未満の場合はその文字列をそのまま返す' do
    assert_equal '20', Ranking.new(name: '20').year
  end

  test 'name が空文字の場合は空文字を返す' do
    assert_equal '', Ranking.new(name: '').year
  end

  test 'of_year は指定年度のランキングのみを返す' do
    result = Ranking.of_year('2015').to_a

    assert_equal [rankings(:kojin2015), rankings(:kuso2015)].map(&:id).sort, result.map(&:id).sort
    assert_not_includes result, rankings(:kojin2016)
  end

  test 'of_year は kind で絞り込める' do
    assert_equal [rankings(:kuso2015)], Ranking.of_year('2015', kind: 'kuso').to_a
    assert_equal [rankings(:kojin2015)], Ranking.of_year('2015', kind: 'kojin').to_a
  end

  test 'of_year は kind に配列を渡すと複数種別を返す' do
    sonota2015 = Ranking.create!(name: '2015年その他ランキング', kind: 'sonota', scope_min: 1, scope_max: 2)

    result = Ranking.of_year('2015', kind: %w[kojin kuso]).to_a
    assert_includes result, rankings(:kuso2015)
    assert_includes result, rankings(:kojin2015)
    assert_not_includes result, sonota2015
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
