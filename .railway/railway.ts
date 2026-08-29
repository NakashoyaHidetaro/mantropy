import {
  defineRailway,
  github,
  postgres,
  preserve,
  project,
  service,
} from "railway/iac";

// Railway Infrastructure as Code (IaC)
//
// 旧 railway.json (Config as Code, 2026-12-01 廃止) の後継。
// このファイルはデプロイ時に読まれるのではなく、`railway config plan` /
// `railway config apply` で Railway 側のサービス設定に反映される。
//
// IaC は「1 プロジェクト 1 ファイル / 書かなければ削除」なので、Postgres と
// 全サービスの環境変数もここに列挙する必要がある。値そのものは Railway 側に
// 置いたままにしたいので preserve() を使う (ソースに秘密情報を書かない)。
//
// このアプリはバックグラウンドジョブ基盤を持たないので web 1 サービス構成。

/** Railway 側に設定済みの値をそのまま維持する環境変数群 */
const webEnv = {
  DATABASE_URL: preserve(),
  SECRET_KEY_BASE: preserve(),
  DEVISE_MAILER_SECRET: preserve(),
  DIGEST_USER: preserve(),
  DIGEST_PASS: preserve(),
  SMTP_PASSWORD: preserve(),
  SLACK_OAUTH_TOKEN: preserve(),
  RAKUTEN_APP_ID: preserve(),
  RAILS_HOST: preserve(),
  RAILS_ENV: preserve(),
  RACK_ENV: preserve(),
  MALLOC_ARENA_MAX: preserve(),
  LANG: preserve(),
  // Railpack イメージに tmp/pids/ が無いため /tmp/server.pid を指定している。
  // omit=delete なので列挙必須(puma.rb 側も PIDFILE 未設定なら書かない対応済み)。
  PIDFILE: preserve(),
};

export default defineRailway(() => {
  const db = postgres("Postgres");

  const source = github("hidesys/mantropy", { branch: "master" });

  // Web (Puma)。preDeploy で db:prepare を流す。
  const web = service("mantropy", {
    source,
    build: { builder: "RAILPACK" },
    start: "bundle exec puma -C config/puma.rb",
    preDeploy: "bundle exec rails db:prepare",
    healthcheck: "/up",
    domains: [
      { domain: "mantropy.net", port: 8080 },
      { domain: "www.mantropy.net", port: 8080 },
    ],
    deploy: {
      restartPolicyType: "ON_FAILURE",
      restartPolicyMaxRetries: 10,
    },
    env: webEnv,
  });

  return project("mantropy", {
    resources: [db, web],
  });
});
