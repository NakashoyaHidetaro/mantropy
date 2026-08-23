require 'test_helper'

class Member::SeriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    @serie = series(:one)
    sign_in @userauth
  end

  test 'new画面を取得できる' do
    get new_member_serie_path
    assert_response :success
  end

  test 'edit画面を取得できる' do
    get edit_member_serie_path(@serie)
    assert_response :success
  end

  test 'ログインしていない場合はログイン画面にリダイレクトされる' do
    sign_out @userauth
    get new_member_serie_path
    assert_redirected_to new_userauth_session_path
  end
  test 'edit画面のURLはpublic_idで生成される' do
    assert_equal "/member/series/#{@serie.public_id}/edit", edit_member_serie_path(@serie)
  end

  test '数値IDを指定したedit画面は404になる' do
    get "/member/series/#{@serie.id}/edit"
    assert_response :not_found
  end
end
