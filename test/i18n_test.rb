require 'test_helper'

# アプリ全体の日本語化(ロケール設定・翻訳ファイル)を検証する
class I18nTest < ActiveSupport::TestCase
  test 'デフォルトロケールが ja である' do
    assert_equal :ja, I18n.default_locale
    assert_includes I18n.available_locales, :ja
  end

  test 'Devise のフラッシュメッセージが日本語である' do
    assert_equal 'ログインしました。', I18n.t('devise.sessions.signed_in')
    assert_equal 'ログアウトしました。', I18n.t('devise.sessions.signed_out')
  end

  test 'Devise のログイン失敗メッセージに日本語の属性名が入る' do
    message = I18n.t('devise.failure.invalid', authentication_keys: Userauth.human_attribute_name(:email))
    assert_equal 'メールアドレスまたはパスワードが違います。', message
  end

  test 'バリデーションエラーが日本語で属性名付きになる' do
    user = User.new
    assert_not user.valid?
    assert_includes user.errors.full_messages, 'ペンネームを入力してください'
    assert_includes user.errors.full_messages, '入トロ年度を入力してください'
  end

  test 'モデル名が日本語で取得できる' do
    assert_equal 'シリーズ', Serie.model_name.human
  end

  test 'ページネーションの文言が日本語である' do
    assert_equal '次 &rsaquo;', I18n.t('views.pagination.next')
    assert_equal '&lsaquo; 前', I18n.t('views.pagination.previous')
  end

  test '日付が日本語の書式で表示される' do
    assert_equal '2026年09月28日(月)', I18n.l(Date.new(2026, 9, 28), format: :long)
  end

  test 'タイムゾーンが東京である' do
    assert_equal 'Tokyo', Time.zone.name
  end
end
