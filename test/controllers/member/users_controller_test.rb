require 'test_helper'

class Member::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    @user = users(:one)
    sign_in @userauth
  end

  test 'new画面を取得できる' do
    sign_out @userauth
    # ユーザー情報未登録のuserauthでログイン
    userauth_without_user = userauths(:two)
    userauth_without_user.update!(user: nil)
    sign_in userauth_without_user
    get new_member_user_path
    assert_response :success
  end

  test 'edit画面を取得できる' do
    get edit_member_user_path(@user)
    assert_response :success
  end

  test 'ログインしていない場合はログイン画面にリダイレクトされる' do
    sign_out @userauth
    get new_member_user_path
    assert_redirected_to new_userauth_session_path
  end
  test 'edit画面のURLはnameで生成される' do
    assert_equal "/member/users/#{@user.name}/edit", edit_member_user_path(@user)
  end

  test '存在しないnameを指定したedit画面は404になる' do
    get '/member/users/nonexistent_user/edit'
    assert_response :not_found
  end
end
