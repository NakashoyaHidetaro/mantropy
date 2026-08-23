require 'test_helper'

class Member::RanksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    @rank = ranks(:kojin2015_user_one_first)
    sign_in @userauth
  end

  test 'ログインしていない場合はログイン画面にリダイレクトされる' do
    sign_out @userauth
    delete member_rank_path(@rank)
    assert_redirected_to new_userauth_session_path
  end

  test '集計中のランキングなら自分の順位を削除できる' do
    travel_to Date.new(2015, 11, 1) do
      assert_difference 'Rank.count', -1 do
        delete member_rank_path(@rank)
      end
      assert_redirected_to user_path(users(:one).name)
    end
  end

  test '集計終了後のランキングの順位は削除できない' do
    assert_no_difference 'Rank.count' do
      delete member_rank_path(@rank)
    end
    assert_redirected_to user_path(@rank.user.name)
    assert flash[:alert].present?
  end

  test '他人の順位は削除できない' do
    other_rank = ranks(:kojin2015_user_two_first)
    travel_to Date.new(2015, 11, 1) do
      assert_no_difference 'Rank.count' do
        delete member_rank_path(other_rank)
      end
      assert_redirected_to user_path(other_rank.user.name)
      assert flash[:alert].present?
    end
  end

  test '集計終了後のランキングには順位を登録できない' do
    assert_no_difference 'Rank.count' do
      post member_ranks_path, params: rank_create_params(rankings(:kojin2015))
    end
    assert_redirected_to user_path(users(:one).name)
    assert flash[:notice].present?
  end

  test '集計中のランキングには順位を登録できる' do
    travel_to Date.new(2015, 11, 1) do
      assert_difference 'Rank.count', 1 do
        post member_ranks_path, params: rank_create_params(rankings(:kojin2015), rank: 3, serie: series(:voted_a))
      end
    end
  end

  private

  def rank_create_params(ranking, rank: 1, serie: series(:one))
    { rank: { rank: rank.to_s, score: 1, ranking_id: ranking.id, serie_id: serie.id },
      magazine_name: '', magazine_placed: '', magazine_id: '' }
  end
end
