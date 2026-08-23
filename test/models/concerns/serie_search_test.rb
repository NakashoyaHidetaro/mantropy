require 'test_helper'

class SerieSearchTest < ActiveSupport::TestCase
  setup do
    @naruto = Serie.create!(name: 'ナルト忍伝')
    @onepiece = Serie.create!(name: 'ワンピース海賊記')
    @kishi_serie = Serie.create!(name: '無題の作品')
    author = Author.create!(name: '岸本ナルヲ')
    AuthorsSerie.create!(author:, serie: @kishi_serie)
  end

  test '1語でシリーズ名の部分一致を検索できる' do
    result = SerieSearch.search('ワンピース')
    assert_includes result, @onepiece
    assert_not_includes result, @naruto
  end

  test '著者名の部分一致でそのシリーズが検索できる' do
    result = SerieSearch.search('岸本')
    assert_includes result, @kishi_serie
    assert_not_includes result, @onepiece
  end

  test 'シリーズ名と著者名のどちらに一致しても結果に含まれる' do
    result = SerieSearch.search('ナル')
    assert_includes result, @naruto
    assert_includes result, @kishi_serie
  end

  test '複数語はANDで絞り込まれる' do
    result = SerieSearch.search('ナル 忍伝')
    assert_includes result, @naruto
    assert_not_includes result, @kishi_serie
  end

  test '全角スペース区切りでも複数語として扱われる' do
    result = SerieSearch.search('ナル　忍伝')
    assert_includes result, @naruto
    assert_not_includes result, @kishi_serie
  end

  test 'シリーズ名と著者名にまたがる複数語のAND検索ができる' do
    result = SerieSearch.search('岸本 無題')
    assert_includes result, @kishi_serie
    assert_not_includes result, @naruto
  end

  test '一致するシリーズが無い場合は空になる' do
    assert_empty SerieSearch.search('該当なしのキーワード')
  end

  test '検索文字列を半角・全角スペースで分割して空要素を除く' do
    assert_equal %w[あ い う], SerieSearch.words(' あ 　い  う ')
  end

  test '検索文字列が空の場合は検索語が空配列になる' do
    assert_empty SerieSearch.words(nil)
  end
end
