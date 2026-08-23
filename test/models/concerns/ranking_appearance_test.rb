require 'test_helper'

class RankingAppearanceTest < ActiveSupport::TestCase
  test '既知の種別にはアイコンとテーマカラーが定義されている' do
    Ranking.kinds.each_key do |kind|
      assert_match(/\Abi bi-[\w-]+\z/, RankingAppearance.icon_class(kind))
      assert_not_equal RankingAppearance::DEFAULT_APPEARANCE[:color], RankingAppearance.color(kind)
    end
  end

  test '種別ごとに異なるアイコンが割り当てられている' do
    icons = Ranking.kinds.keys.map { |kind| RankingAppearance.icon_class(kind) }
    assert_equal icons.size, icons.uniq.size
  end

  test '未知の種別にはフォールバックの見た目を返す' do
    assert_equal RankingAppearance::DEFAULT_APPEARANCE, RankingAppearance.for_kind('unknown')
  end

  test 'Ranking から種別ごとの見た目を参照できる' do
    ranking = rankings(:kojin2015)
    assert_equal RankingAppearance.icon_class('kojin'), ranking.icon_class
    assert_equal RankingAppearance.color('kojin'), ranking.theme_color
    assert_equal Ranking::KIND_NAMES['kojin'], ranking.kind_name
  end
end
