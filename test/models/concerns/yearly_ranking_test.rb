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
end
