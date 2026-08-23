require 'test_helper'

class Userauths::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # 登録ページはHTTP Basic認証で保護されているため、認証情報を用意する
    @original_digest_user = ENV.fetch('DIGEST_USER', nil)
    @original_digest_pass = ENV.fetch('DIGEST_PASS', nil)
    ENV['DIGEST_USER'] = 'digest_user'
    ENV['DIGEST_PASS'] = 'digest_pass'
    @auth_headers = {
      'HTTP_AUTHORIZATION' =>
        ActionController::HttpAuthentication::Basic.encode_credentials('digest_user', 'digest_pass')
    }
  end

  teardown do
    ENV['DIGEST_USER'] = @original_digest_user
    ENV['DIGEST_PASS'] = @original_digest_pass
  end

  test '新規登録画面を取得できる' do
    get new_userauth_registration_path, headers: @auth_headers
    assert_response :success
  end

  test '新規登録画面に必須項目の凡例が表示される' do
    get new_userauth_registration_path, headers: @auth_headers
    assert_select 'p.form-text', text: '* は必須項目です'
  end

  test '新規登録画面の必須項目ラベルに赤いアスタリスクが付く' do
    get new_userauth_registration_path, headers: @auth_headers
    # email / password / password_confirmation の3項目 + 凡例の1つで合計4つ
    assert_select 'span.text-danger', text: '*', count: 4
    %w[userauth_email userauth_password userauth_password_confirmation].each do |id|
      assert_select 'label[for=?] span.text-danger', id, text: '*'
    end
  end

  test 'Basic認証の情報がない場合は認証を要求される' do
    get new_userauth_registration_path
    assert_response :unauthorized
  end
end
