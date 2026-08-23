require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test 'content_for :title が未設定ならtitleは空になる（レイアウトはサイト名のみを表示する）' do
    assert_predicate title, :blank?
  end

  test 'content_for :title で設定した文字列をtitleが返す' do
    content_for :title, 'テストページ'
    assert_equal 'テストページ', title
  end

  test 'x_share_buttonはXの共有インテントURLへのリンクを生成する' do
    html = x_share_button('作品名 - 漫トロピーWeb', 'https://example.com/series/1')
    assert_includes html, 'https://x.com/intent/post?'
    # テキストとURLがクエリとしてエンコードされていること
    assert_includes html, CGI.escape('作品名 - 漫トロピーWeb')
    assert_includes html, CGI.escape('https://example.com/series/1')
  end

  test 'x_share_buttonのリンクは別タブで開き、noopenerが付く' do
    html = x_share_button('t', 'https://example.com/')
    assert_includes html, 'target="_blank"'
    assert_includes html, 'rel="noopener"'
  end
end
