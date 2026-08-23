require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test 'content_for :title が未設定ならtitleは空になる（レイアウトはサイト名のみを表示する）' do
    assert_predicate title, :blank?
  end

  test 'content_for :title で設定した文字列をtitleが返す' do
    content_for :title, 'テストページ'
    assert_equal 'テストページ', title
  end
end
