# frozen_string_literal: true

require 'test_helper'

class RackAttackRulesTest < ActiveSupport::TestCase
  # Acceptヘッダだけを持つダミーのRackリクエストを作る
  def request_with_accept(accept)
    env = Rack::MockRequest.env_for('/')
    env['HTTP_ACCEPT'] = accept if accept
    Rack::Attack::Request.new(env)
  end

  test '実際に観測されたSQLiプローブのAcceptヘッダを不正と判定する' do
    assert RackAttackRules.malicious_accept_header?(request_with_accept('-1" OR 5*5=25 or "45ArixcZ"="'))
  end

  test 'すり抜けが観測されたプローブのAcceptヘッダを不正と判定する' do
    [
      "Cgwz60'XOR(if(now()=sysdate()",
      'if(now()=sysdate()',
      "quzrW3E87nJ3Y'",
      '../../../../../../../../etc/passwd{{',
      'YJWk10"XOR(if(now()=sysdate(),sleep(15),0))XOR"Z'
    ].each do |accept|
      assert RackAttackRules.malicious_accept_header?(request_with_accept(accept)), "不正と判定されるべき: #{accept}"
    end
  end

  test '典型的なSQLiパターンを不正と判定する' do
    [
      "' OR 1=1 --",
      'text/html UNION SELECT password FROM users',
      'text/html UNION ALL SELECT 1,2,3',
      "1' AND SLEEP(5) AND 'a'='a",
      "1' AND pg_sleep(5)--",
      "1 AND BENCHMARK(10000000,MD5('a'))",
      "1;WAITFOR DELAY '0:0:5'--",
      'SELECT name FROM users WHERE id=1'
    ].each do |accept|
      assert RackAttackRules.malicious_accept_header?(request_with_accept(accept)), "不正と判定されるべき: #{accept}"
    end
  end

  test '正規のAcceptヘッダを不正と判定しない' do
    [
      'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'application/json, text/plain, */*',
      '*/*',
      'text/css,*/*;q=0.1',
      'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      'application/signed-exchange;v=b3;q=0.7',
      'text/html; charset="utf-8"',
      'application/vnd.api+json'
    ].each do |accept|
      assert_not RackAttackRules.malicious_accept_header?(request_with_accept(accept)), "正規と判定されるべき: #{accept}"
    end
  end

  test 'Acceptヘッダが無い場合は不正と判定しない' do
    assert_not RackAttackRules.malicious_accept_header?(request_with_accept(nil))
    assert_not RackAttackRules.malicious_accept_header?(request_with_accept(''))
  end

  test '静的アセットとヘルスチェックのパスはthrottle対象外になる' do
    assert RackAttackRules.excluded_path?('/assets/application-abc123.css')
    assert RackAttackRules.excluded_path?('/up')
    assert RackAttackRules.excluded_path?('/favicon.ico')
    assert RackAttackRules.excluded_path?('/robots.txt')
  end

  test '通常のパスはthrottle対象になる' do
    assert_not RackAttackRules.excluded_path?('/')
    assert_not RackAttackRules.excluded_path?('/users/sign_in')
    assert_not RackAttackRules.excluded_path?('/about')
  end
end
