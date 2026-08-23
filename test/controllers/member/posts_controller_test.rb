require 'test_helper'

class Member::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    @topic = topics(:one)
    sign_in @userauth
  end

  test 'スレッドへ書き込みできる' do
    assert_difference('Post.count', 1) do
      post member_posts_path, params: { topic_id: @topic.id, post: { content: 'テスト書き込み', email: '' } }
    end
    assert_redirected_to member_topic_show_path(@topic)
  end

  test 'ログインしていない場合はログイン画面にリダイレクトされる' do
    sign_out @userauth
    post member_posts_path, params: { topic_id: @topic.id, post: { content: 'テスト書き込み', email: '' } }
    assert_redirected_to new_userauth_session_path
  end
end
