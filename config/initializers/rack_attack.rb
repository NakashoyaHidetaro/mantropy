# frozen_string_literal: true

# Rack::Attack の設定。
# Rails のルーティングより手前（ミドルウェア層）で不正リクエストを遮断する。
#
# 判定ロジック本体は app/models/concerns/rack_attack_rules.rb にある。
# 各ブロックはリクエスト毎に評価されるため、ここで定数を参照しても autoload 上の問題はない。

# ---------------------------------------------
# キャッシュストア
# ---------------------------------------------
# throttle / Fail2Ban のカウンタ置き場。アプリの Rails.cache に合わせる。
# ただし test 環境などで :null_store が使われている場合はカウントできないため、
# プロセスローカルの MemoryStore にフォールバックする。
Rack::Attack.cache.store =
  if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
    ActiveSupport::Cache::MemoryStore.new
  else
    Rails.cache
  end

# ---------------------------------------------
# blocklist: SQLi プローブの遮断（403）
# ---------------------------------------------
# `-1" OR 5*5=25 or "45ArixcZ"="` のような Accept ヘッダを付けた
# SQLi スキャンが大量に来ているため、Rails に到達する前に 403 で返す。
#
# Fail2Ban.filter は「マッチしたリクエスト自体をブロックしつつ、
# 一定時間内に規定回数マッチした IP を bantime の間まとめて遮断する」挙動になる。
# そのため blocklist はこの 1 本で「即 403」と「繰り返し犯の IP ban」の両方を兼ねる。
#
# NOTE: blocklist は登録順に評価され、最初にマッチしたものが採用される。
#       カウントを取りこぼさないよう Fail2Ban を最初に登録すること。
Rack::Attack.blocklist('fail2ban: 不正なAcceptヘッダの繰り返し') do |req|
  Rack::Attack::Fail2Ban.filter("accept-sqli:#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
    RackAttackRules.malicious_accept_header?(req)
  end
end

# 念のための保険。Fail2Ban のカウンタが失われた場合でも、
# 明らかな SQLi パターンを含むリクエストは常に 403 にする。
Rack::Attack.blocklist('不正なAcceptヘッダ') do |req|
  RackAttackRules.malicious_accept_header?(req)
end

# ---------------------------------------------
# throttle: IP 単位の全体レートリミット
# ---------------------------------------------
# 5分間に300リクエストを超えたら 429 を返す。
# 静的アセットやヘルスチェックは1ページ表示で大量に叩かれるためカウントしない。
Rack::Attack.throttle('req/ip', limit: 300, period: 5.minutes) do |req|
  req.ip unless RackAttackRules.excluded_path?(req.path)
end

# ---------------------------------------------
# レスポンス
# ---------------------------------------------
Rack::Attack.blocklisted_responder = lambda do |_request|
  [403, { 'content-type' => 'text/plain; charset=utf-8' }, ["Forbidden\n"]]
end

Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env['rack.attack.match_data'] || {}
  retry_after = (match_data[:period] || 60).to_i

  [
    429,
    { 'content-type' => 'text/plain; charset=utf-8', 'retry-after' => retry_after.to_s },
    ["Too Many Requests\n"]
  ]
end

# ---------------------------------------------
# ログ
# ---------------------------------------------
ActiveSupport::Notifications.subscribe(/rack_attack/) do |_name, _start, _finish, _id, payload|
  req = payload[:request]
  next if req.nil?

  Rails.logger.warn(
    "[Rack::Attack] #{req.env['rack.attack.match_type']} rule=#{req.env['rack.attack.matched']} " \
    "ip=#{req.ip} path=#{req.path} accept=#{req.get_header('HTTP_ACCEPT').inspect}"
  )
end
