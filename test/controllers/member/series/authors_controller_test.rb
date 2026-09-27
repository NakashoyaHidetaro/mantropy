require 'test_helper'

class Member::Series::AuthorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    @serie = series(:one)
    sign_in @userauth
  end

  test 'ログインしていない場合はログイン画面にリダイレクトされる' do
    sign_out @userauth
    patch member_serie_author_path(@serie)
    assert_redirected_to new_userauth_session_path
  end

  test '作者名が空の場合は500にならずエラー内容つきでリダイレクトされる' do
    assert_no_difference 'Author.count' do
      patch member_serie_author_path(@serie), params: { mode: 'add', author_name: '' },
                                              headers: { 'HTTP_REFERER' => serie_path(@serie) }
    end
    assert_redirected_to serie_path(@serie)
    assert flash[:alert].present?
  end
end
