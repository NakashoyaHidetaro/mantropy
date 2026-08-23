require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  test 'ユーザー一覧画面を取得できる' do
    get users_path
    assert_response :success
  end

  test 'ユーザー詳細画面を取得できる' do
    user = users(:one)
    get user_path(user.name)
    assert_response :success
  end

  test '存在しないユーザーの場合はリダイレクトされる' do
    get user_path('nonexistent_user')
    assert_redirected_to users_path
  end

  test 'ゲストにはmember専用リンクが表示されない' do
    user = users(:one)
    get user_path(user.name)
    assert_response :success
    assert_select "a[href^='/member/']", false
  end
end
