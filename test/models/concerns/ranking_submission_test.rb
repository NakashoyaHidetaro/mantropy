require 'test_helper'

class RankingSubmissionTest < ActiveSupport::TestCase
  test 'ゲスト（user が nil）はダウンロードできない' do
    assert_not RankingSubmission.member_list_downloadable?(nil)
  end

  test '集計中のランキングが無ければログイン済みユーザーはダウンロードできる' do
    assert RankingSubmission.member_list_downloadable?(users(:one))
  end

  test '集計中でも未提出のユーザーはダウンロードできない' do
    rankings(:kojin2016).update!(aggregation_ends_on: Date.current)
    assert_not RankingSubmission.member_list_downloadable?(users(:one))
  end

  test '集計中でも提出完了したユーザーはダウンロードできる' do
    rankings(:kojin2016).update!(aggregation_ends_on: Date.current)
    create_kojin_ranks_of_year2016(users(:one))
    assert RankingSubmission.member_list_downloadable?(users(:one))
  end

  test '集計中の年度に属するランキング群を取得できる' do
    rankings(:kojin2016).update!(aggregation_ends_on: Date.current)
    assert_includes RankingSubmission.registering_rankings, rankings(:kojin2016)
    assert_not_includes RankingSubmission.registering_rankings, rankings(:kojin2015)
  end

  test '集計中のランキングが無ければ registering_rankings は空になる' do
    assert_empty RankingSubmission.registering_rankings
  end

  private

  def create_kojin_ranks_of_year2016(user)
    Rank.create!(rank: 1, ranking: rankings(:kojin2016), user: user, serie: series(:one))
    Rank.create!(rank: 2, ranking: rankings(:kojin2016), user: user, serie: series(:two))
  end
end
