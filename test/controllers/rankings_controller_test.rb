require 'test_helper'

class RankingsControllerTest < ActionDispatch::IntegrationTest
  test 'ランキング一覧画面を取得できる' do
    get rankings_path
    assert_response :success
  end

  test '一般公開済みのランキングはゲストにもリンクされる' do
    get rankings_path
    assert_response :success
    assert_select 'a[href=?]', ranking_series_path(rankings(:kojin2015))
  end

  test '集計中のランキングはゲストにはリンクされない' do
    travel_to Date.new(2015, 11, 1) do
      get rankings_path
      assert_response :success
      assert_select 'a[href=?]', ranking_series_path(rankings(:kojin2015)), false
    end
  end

  test '集計中のランキングもログインユーザーにはリンクされる' do
    sign_in userauths(:one)
    travel_to Date.new(2015, 11, 1) do
      get rankings_path
      assert_response :success
      assert_select 'a[href=?]', ranking_series_path(rankings(:kojin2015))
    end
  end
end
