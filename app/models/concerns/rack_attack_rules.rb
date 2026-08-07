# frozen_string_literal: true

# Rack::Attack で使う「不正リクエスト判定」のロジックをまとめたモジュール。
#
# config/initializers/rack_attack.rb から参照されるが、
# イニシャライザのブロックはリクエスト毎に評価されるため、
# ここを autoload 対象の app/models/concerns に置いても問題ない。
module RackAttackRules
  # Accept ヘッダに混入する SQL インジェクションのプローブ文字列パターン。
  #
  # Accept ヘッダは本来 MIME タイプと q パラメータしか含まないため、
  # 引用符や SQL 予約語の組み合わせが現れることは通常ありえない。
  # ただし過剰マッチで正規ユーザーを弾かないよう、
  # 「SQL としか解釈できない並び」に限定した保守的なパターンのみを列挙する。
  SQLI_PATTERNS = [
    /\bor\b\s+\d+\s*\*\s*\d+\s*=/i,        # OR 5*5=25
    /\bor\b\s+\d+\s*=\s*\d+/i,             # OR 1=1
    /["']\s*(?:or|and)\s*["']/i,           # " OR "
    /["']\s*=\s*["']/,                     # "="
    /\bunion\b\s+(?:all\s+)?\bselect\b/i,  # UNION SELECT
    /\bselect\b.+\bfrom\b.+\bwhere\b/i,    # SELECT ... FROM ... WHERE
    /\bsleep\s*\(\s*\d+/i,                 # SLEEP(5)
    /\bpg_sleep\s*\(/i,                    # pg_sleep(5)
    /\bbenchmark\s*\(\s*\d+/i,             # BENCHMARK(10000000,...)
    /\bwaitfor\s+delay\b/i,                # WAITFOR DELAY '0:0:5'
    /\bxor\s*\(/i,                         # XOR(if(now()=sysdate(),...
    /\bnow\s*\(\s*\)\s*=\s*sysdate\s*\(/i, # if(now()=sysdate(),...
    %r{(?:\.\./){2,}},                     # ../../../../etc/passwd（パストラバーサル）
    /'\s*(?:--)?\s*\z/                     # 末尾の裸のシングルクォート（quzrW3E87nJ3Y' 等のプローブ）
  ].freeze

  # throttle の対象外にするパス。静的アセットとヘルスチェックは
  # 1ページの表示で大量にリクエストされるため除外する。
  EXCLUDED_PATH_PREFIXES = %w[
    /assets
    /up
    /favicon.ico
    /robots.txt
    /service-worker.js
  ].freeze

  class << self
    # Accept ヘッダに SQLi のプローブらしき文字列が含まれるか。
    def malicious_accept_header?(request)
      accept = request.get_header('HTTP_ACCEPT')
      return false if accept.blank?

      sqli?(accept)
    end

    # 与えられた文字列が SQLi パターンにマッチするか。
    def sqli?(value)
      SQLI_PATTERNS.any? { |pattern| pattern.match?(value) }
    end

    # レートリミットの計測対象外のパスか。
    def excluded_path?(path)
      EXCLUDED_PATH_PREFIXES.any? { |prefix| path.start_with?(prefix) }
    end
  end
end
