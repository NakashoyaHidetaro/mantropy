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

  test 'new画面のシリーズ名には必須マークと凡例が表示される' do
    get new_member_serie_path
    assert_response :success
    assert_select 'label[for=serie_name] span.text-danger', text: '*'
    assert_select 'p.form-text', text: /は必須項目です/
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

  test '作者名が空の場合は500にならず422でnewが再表示される' do
    assert_no_difference 'Serie.count' do
      post member_series_path,
           params: { serie: { name: '新シリーズ' },
                     author_name: '', author_id: '',
                     magazine_name: 'MyString', magazine_id: '', magazine_publisher: '' }
    end
    assert_response :unprocessable_content
  end

  test 'シリーズ名が空の場合は500にならず422でnewが再表示される' do
    assert_no_difference 'Serie.count' do
      post member_series_path,
           params: { serie: { name: '' },
                     author_name: 'MyString', author_id: '',
                     magazine_name: 'MyString', magazine_id: '', magazine_publisher: '' }
    end
    assert_response :unprocessable_content
  end
end
