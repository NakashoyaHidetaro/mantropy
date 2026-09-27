require 'test_helper'

class RankAggregationTest < ActiveSupport::TestCase
  # rank_info だけを持つ Serie を組み立てる
  def build_serie(rank_info)
    serie = Serie.new
    serie.rank_info = rank_info
    serie
  end

  test '比較キーがすべて等しい漫画には同じ順位が付く' do
    series = [
      build_serie(sum_of_mark: 10, count_rank: 2, min_rank: 1),
      build_serie(sum_of_mark: 10, count_rank: 2, min_rank: 1),
      build_serie(sum_of_mark: 5,  count_rank: 1, min_rank: 3)
    ]
    RankAggregation.assign_ranks(series, keys: %i[sum_of_mark count_rank min_rank])
    assert_equal([1, 1, 3], series.map { |s| s.rank_info[:rank] })
  end

  test '同順位が続いた分だけ次の順位は飛び番になる' do
    series = [
      build_serie(sum_of_mark: 10),
      build_serie(sum_of_mark: 10),
      build_serie(sum_of_mark: 10),
      build_serie(sum_of_mark: 1)
    ]
    RankAggregation.assign_ranks(series, keys: %i[sum_of_mark])
    assert_equal([1, 1, 1, 4], series.map { |s| s.rank_info[:rank] })
  end

  test '比較キーの一部でも異なれば別の順位になる' do
    series = [
      build_serie(sum_of_mark: 10, count_rank: 2, min_rank: 1),
      build_serie(sum_of_mark: 10, count_rank: 2, min_rank: 2)
    ]
    RankAggregation.assign_ranks(series, keys: %i[sum_of_mark count_rank min_rank])
    assert_equal([1, 2], series.map { |s| s.rank_info[:rank] })
  end

  test '糞ランキング用の比較キーでも順位を付与できる' do
    series = [
      build_serie(sum_of_mark_with_kuso: -1, count_kuso: 1, min_rank: 1),
      build_serie(sum_of_mark_with_kuso: -1, count_kuso: 1, min_rank: 1)
    ]
    RankAggregation.assign_ranks(series, keys: %i[sum_of_mark_with_kuso count_kuso min_rank])
    assert_equal([1, 1], series.map { |s| s.rank_info[:rank] })
  end

  test '空配列を渡しても例外にならない' do
    assert_equal [], RankAggregation.assign_ranks([], keys: %i[sum_of_mark])
  end

  test 'sort_ranks はランキングID順・同一ランキング内は順位順に並べ替える' do
    kojin = rankings(:kojin2015)
    kuso = Ranking.create!(year: 2054, kind: :kuso, scope_min: 1, scope_max: 2,
                           aggregation_ends_on: Date.new(2054, 11, 20), published_on: Date.new(2054, 12, 31))
    r1 = Rank.create!(rank: 2, ranking: kojin, user: users(:two), serie: series(:one))
    r2 = Rank.create!(rank: 1, ranking: kojin, user: users(:two), serie: series(:two))
    r3 = Rank.create!(rank: 1, ranking: kuso, user: users(:two), serie: series(:one))

    assert_equal [r2, r1, r3], RankAggregation.sort_ranks([r3, r1, r2])
  end

  test 'ranks_by_year は年度降順でまとめて返す' do
    Rank.create!(rank: 1, ranking: rankings(:kojin2016), user: users(:one), serie: series(:one))
    grouped = RankAggregation.ranks_by_year(users(:one))

    years = grouped.keys.select { |y| [2015, 2016].include?(y) }
    assert_equal [2016, 2015], years
    assert_equal 2, grouped[2015].size
    assert_equal 1, grouped[2016].size
  end

  test 'ranks_by_year は excluded_years で指定した年度を除外する' do
    Rank.create!(rank: 1, ranking: rankings(:kojin2016), user: users(:one), serie: series(:one))
    grouped = RankAggregation.ranks_by_year(users(:one), excluded_years: [2016])

    assert_not_includes grouped.keys, 2016
    assert_includes grouped.keys, 2015
  end

  test 'ranks_by_year は年度内の ranks をランキングID順・順位順に並べる' do
    grouped = RankAggregation.ranks_by_year(users(:one))
    assert_equal [1, 2], grouped[2015].map(&:rank)
  end

  test 'complete_ranking? は規定順位をすべて提出済みなら true を返す' do
    assert RankAggregation.complete_ranking?(rankings(:kojin2015), users(:one))
  end

  test 'complete_ranking? は提出が足りなければ false を返す' do
    assert_not RankAggregation.complete_ranking?(rankings(:kojin2015), users(:two))
  end

  test 'complete_ranking? はユーザーが nil なら false を返す' do
    assert_not RankAggregation.complete_ranking?(rankings(:kojin2015), nil)
  end

  test 'complete_ranking? は漫画が削除済みの rank を 0 として扱い未完了とみなす' do
    ranking = Ranking.create!(year: 2017, kind: :kojin, scope_min: 1, scope_max: 1,
                              aggregation_ends_on: Date.new(2017, 11, 20), published_on: Date.new(2017, 12, 31))
    rank = Rank.create!(rank: 1, ranking: ranking, user: users(:two), serie: series(:one))
    # serie_id は NOT NULL なので、存在しない id を指す(削除済み漫画)状態を再現する
    rank.update_columns(serie_id: Serie.maximum(:id) + 1) # rubocop:disable Rails/SkipsModelValidations

    assert_not RankAggregation.complete_ranking?(ranking, users(:two))
  end
end
