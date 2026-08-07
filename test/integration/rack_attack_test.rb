# frozen_string_literal: true

require 'test_helper'

class RackAttackTest < ActionDispatch::IntegrationTest
  # 実際に観測されているSQLiプローブのAcceptヘッダ
  MALICIOUS_ACCEPT = '-1" OR 5*5=25 or "45ArixcZ"="'
  # ブラウザが送る一般的なAcceptヘッダ
  NORMAL_ACCEPT = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8'

  def setup
    # test_helper.rbで無効化しているので、このテストの間だけ有効にする
    Rack::Attack.enabled = true
    # Fail2Ban/throttleのカウンタを毎テストごとにリセットし、
    # テスト間およびテスト環境の:null_storeの影響を受けないようにする
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  def teardown
    Rack::Attack.enabled = false
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  test '不正なAcceptヘッダのリクエストは403で遮断される' do
    get root_path, headers: { 'HTTP_ACCEPT' => MALICIOUS_ACCEPT }

    assert_response :forbidden
  end

  test 'UNION SELECTを含むAcceptヘッダのリクエストは403で遮断される' do
    get root_path, headers: { 'HTTP_ACCEPT' => 'text/html UNION SELECT password FROM users' }

    assert_response :forbidden
  end

  test '通常のAcceptヘッダのリクエストは通る' do
    get root_path, headers: { 'HTTP_ACCEPT' => NORMAL_ACCEPT }

    assert_response :success
  end

  test 'JSON APIのようなAcceptヘッダのリクエストも通る' do
    get root_path, headers: { 'HTTP_ACCEPT' => 'application/json, text/plain, */*' }

    assert_response :success
  end

  test '不正なAcceptヘッダを繰り返すIPはFail2Banで一定時間banされる' do
    # findtime(10分)以内にmaxretry(3回)到達させる
    3.times do
      get root_path, headers: { 'HTTP_ACCEPT' => MALICIOUS_ACCEPT }
      assert_response :forbidden
    end

    # ban後は正常なAcceptヘッダでも遮断される
    get root_path, headers: { 'HTTP_ACCEPT' => NORMAL_ACCEPT }
    assert_response :forbidden
  end

  test 'Rack::Attackを無効にすれば不正なAcceptヘッダでも遮断されない' do
    Rack::Attack.enabled = false

    get root_path, headers: { 'HTTP_ACCEPT' => MALICIOUS_ACCEPT }

    # Rails自身が406を返す(Rack::Attackの403ではない)
    assert_not_equal 403, response.status
  end
end
