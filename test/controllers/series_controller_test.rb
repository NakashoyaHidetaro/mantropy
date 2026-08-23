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

  test 'ゲストのシリーズ詳細画面にはmember専用リンクが表示されない' do
    get serie_path(series(:one))
    assert_response :success
    assert_select "a[href^='/member/']", false
  end
end
