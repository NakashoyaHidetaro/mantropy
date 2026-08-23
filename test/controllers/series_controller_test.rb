require 'test_helper'

class SeriesControllerTest < ActionDispatch::IntegrationTest
  test '検索ワードがない場合はリダイレクトされる' do
    get series_path
    assert_redirected_to root_path
  end

  test '検索ワードを指定して検索できる' do
    get series_path, params: { str: 'test' }
    assert_response :success
  end

  test 'シリーズ詳細画面のURLはpublic_idで生成される' do
    serie = series(:one)
    assert_equal "/series/#{serie.public_id}", serie_path(serie)
  end

  test 'public_idを指定してシリーズ詳細画面を取得できる' do
    serie = series(:one)
    get serie_path(serie)
    assert_response :success
  end

  test '存在しないpublic_idを指定すると404になる' do
    get '/series/0000000000000000'
    assert_response :not_found
  end

  test '旧URL(/series/:id)は新URLへ恒久リダイレクトされる' do
    serie = series(:one)
    get "/series/#{serie.id}"
    assert_response :moved_permanently
    assert_redirected_to serie_path(serie)
  end

  test '旧URL(/:name/series/:id)は新URLへ恒久リダイレクトされる' do
    serie = series(:one)
    get "/somename/series/#{serie.id}"
    assert_response :moved_permanently
    assert_redirected_to serie_path(serie)
  end

  test '存在しない数値IDの旧URLは404になる' do
    get '/series/999999999'
    assert_response :not_found
  end

  test '複数語で検索しても例外にならずAND条件で絞り込まれる' do
    # 1件だけだと詳細画面へリダイレクトされてしまうので、一致するシリーズは2件用意する
    Serie.create!(name: '複数語ヒット作品A')
    Serie.create!(name: '複数語ヒット作品B')
    Serie.create!(name: '複数語だけの作品')
    get series_path, params: { str: '複数語 ヒット' }
    assert_response :success
    assert_select 'a', text: '複数語ヒット作品A'
    assert_select 'a', text: '複数語だけの作品', count: 0
  end

  test '集計中のランキングの順位は詳細画面の@ranksに含まれない' do
    serie = series(:one)
    registerable = Ranking.create!(name: '集計中ランキング', is_registerable: true)
    Rank.create!(ranking: registerable, serie:, user: users(:one), rank: 1, score: 1)
    finished = Ranking.create!(name: '集計済みランキング', is_registerable: false)
    Rank.create!(ranking: finished, serie:, user: users(:one), rank: 1, score: 1)

    get serie_path(serie)
    assert_response :success
    assert_select 'td', text: '集計中ランキング', count: 0
    assert_select 'td', text: '集計済みランキング'
  end

  test 'トピック未設定のシリーズを表示するとトピックが作成される' do
    serie = Serie.create!(name: 'トピック未設定シリーズ')
    assert_nil serie.topic
    assert_difference 'Topic.count', 1 do
      get serie_path(serie)
    end
    assert_response :success
    assert_not_nil serie.reload.topic
  end

  test 'ゲストのシリーズ詳細画面にはmember専用リンクが表示されない' do
    get serie_path(series(:one))
    assert_response :success
    assert_select "a[href^='/member/']", false
  end
end
