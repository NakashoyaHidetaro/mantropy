require 'test_helper'

class Member::RanksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    @rank = ranks(:one)
    sign_in @userauth
  end

  test 'ログインしていない場合はログイン画面にリダイレクトされる' do
    sign_out @userauth
    delete member_rank_path(@rank)
    assert_redirected_to new_userauth_session_path
  end
end
