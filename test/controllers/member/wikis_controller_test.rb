require 'test_helper'

class Member::WikisControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userauth = userauths(:one)
    @wiki = wikis(:one)
    sign_in @userauth
  end

  test 'index画面を取得できる' do
    get member_wikis_path
    assert_response :success
  end

  test 'new画面を取得できる' do
    get new_member_wiki_path
    assert_response :success
  end

  test 'new画面の必須項目には必須マークと凡例が表示される' do
    get new_member_wiki_path
    assert_response :success
    # ページ名・タイトル・内容が必須
    %w[name title content].each do |attribute|
      assert_select 'label[for=?] span.text-danger', "wiki_#{attribute}", text: '*'
    end
    assert_select 'p.form-text', text: /は必須項目です/
    # 公開範囲は任意項目なので * は付かない
    assert_select 'label[for=?] span.text-danger', 'wiki_is_private', false
  end

  test 'ビューでページタイトルがcontent_forに設定される' do
    get edit_member_wiki_path(@wiki)
    assert_response :success
    # コントローラの @title ではなくビュー側の content_for :title でタイトルを渡すため、
    # 対象レコード名を含んだタイトルが <title> に反映される
    assert_select 'head title', text: /#{Regexp.escape(@wiki.name)} の編集/
  end

  test 'ログインしていない場合はログイン画面にリダイレクトされる' do
    sign_out @userauth
    get member_wikis_path
    assert_redirected_to new_userauth_session_path
  end
end
