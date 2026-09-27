require 'test_helper'

class Member::Series::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    @serie = series(:one)
    sign_in @userauth
  end

  test 'ログインしていない場合はログイン画面にリダイレクトされる' do
    sign_out @userauth
    patch member_serie_post_path(@serie)
    assert_redirected_to new_userauth_session_path
  end

  test '本文が空の書き込みは500にならずエラー内容つきでリダイレクトされる' do
    serie = series(:voted_a)
    assert_no_difference 'Post.count' do
      patch member_serie_post_path(serie),
            params: { topic_id: serie.topic_id, post: { content: '', email: '' } },
            headers: { 'HTTP_REFERER' => serie_path(serie) }
    end
    assert_redirected_to serie_path(serie)
    assert flash[:alert].present?
  end
end
