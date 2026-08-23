require 'test_helper'

class Member::TopicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    @topic = topics(:one)
    sign_in @userauth
  end

  test 'index画面を取得できる' do
    get member_topics_path
    assert_response :success
  end

  test 'new画面を取得できる' do
    get new_member_topic_path
    assert_response :success
  end

  test 'edit画面を取得できる' do
    get edit_member_topic_path(@topic)
    assert_response :success
  end

  test 'new画面には必須項目がないため必須マークと凡例は表示されない' do
    get new_member_topic_path
    assert_response :success
    # Topicモデルにpresenceバリデーションが無いので必須マークは付けない
    assert_select 'label span.text-danger', false
    assert_select 'p.form-text', { text: /は必須項目です/, count: 0 }
  end

  test 'ログインしていない場合はログイン画面にリダイレクトされる' do
    sign_out @userauth
    get member_topics_path
    assert_redirected_to new_userauth_session_path
  end
end
