require 'test_helper'

class SerieRankingExportTest < ActiveSupport::TestCase
  setup do
    @kojin = create_ranking(2013, :kojin)
    @kuso = create_ranking(2013, :kuso)
    @ranking_ids = [@kojin.id, @kuso.id]
    @serie = build_exported_serie
  end

  test 'plain_text は改行と XML で使えない制御文字を取り除き、& や < やタブはそのまま残す' do
    assert_equal("A&B<C>タブ\tD", SerieRankingExport.plain_text("A&B<C>\r\nタブ\tD\u0008"))
  end

  test 'plain_text は nil を空文字列にする' do
    assert_equal('', SerieRankingExport.plain_text(nil))
  end

  test 'entry は順位・得点・作者・掲載誌・レビュー・コメントを整形して返す' do
    entry = SerieRankingExport.entry(@serie, @ranking_ids, comment_brackets: SerieRankingExport::XML_COMMENT_BRACKETS)

    assert_equal('1位', entry[:rank])
    assert_equal('出力テスト漫画', entry[:name])
    assert_equal('作者甲・作者乙', entry[:authors])
    assert_equal('（7点： 得票数2, クソ修正後得点-2点, クソ得票数1）', entry[:ranking])
    assert_equal('週刊テスト（巻頭）　月刊テスト', entry[:magazine])
    assert_equal({ content: 'レビュー&本文', by: users(:one).name }, entry[:detail])
    assert_equal("コメント1【#{users(:two).name}:2位】\nコメント2【#{users(:three).name}:糞1位】\n" \
                 "コメント3【#{users(:four).name}】", entry[:comments])
  end

  test 'entry はコメントの括弧を差し替えられる' do
    entry = SerieRankingExport.entry(@serie, @ranking_ids, comment_brackets: SerieRankingExport::JSON_COMMENT_BRACKETS)
    assert entry[:comments].start_with?("コメント1（#{users(:two).name}:2位）")
  end

  test 'entry はレビューもトピックも無ければ detail を空にし comments を nil にする' do
    @serie.post = nil
    @serie.topic = nil
    entry = SerieRankingExport.entry(@serie, @ranking_ids, comment_brackets: SerieRankingExport::XML_COMMENT_BRACKETS)
    assert_empty entry[:detail]
    assert_nil entry[:comments]
  end

  test 'csv はヘッダ行と作品ごとの集計行を出力し、カンマや & を含む値も崩さない' do
    @serie.update!(name: 'A&B, C')
    rows = CSV.parse(SerieRankingExport.csv([@serie], @ranking_ids))

    assert_equal(SerieRankingExport::CSV_HEADER, rows[0])
    assert_equal(['1', '7', '-2', '2', '1', '3', @serie.id.to_s, 'A&B, C', '作者甲　作者乙', '週刊テスト　月刊テスト',
                  "#{users(:one).name} (1位)　#{users(:two).name} (2位)　#{users(:three).name} (糞1位)"], rows[1])
  end

  test 'filename は今日の日付とランキング名と拡張子からファイル名を作る' do
    travel_to Time.zone.local(2026, 10, 31, 12) do
      assert_equal('20261031_2013年漫トロ個人ランキング.xml', SerieRankingExport.filename(@kojin, :xml))
    end
  end

  private

  def create_ranking(year, kind)
    Ranking.create!(year:, kind:, scope_min: 1, scope_max: 2,
                    aggregation_ends_on: Date.new(year, 11, 20), published_on: Date.new(year, 12, 31))
  end

  # レビュー・コメント・票・作者・掲載誌がひととおり揃った漫画を作る
  def build_exported_serie
    topic = Topic.create!(title: nil)
    review = Post.create!(content: "レビュー&\r\n本文", topic:, user: users(:one))
    serie = Serie.create!(name: '出力テスト漫画', topic:, post: review)
    %w[作者甲 作者乙].each { |name| serie.authors << Author.create!(name:) }
    serie.magazines_series.create!(magazine: Magazine.create!(name: '週刊テスト'), placed: '巻頭')
    serie.magazines_series.create!(magazine: Magazine.create!(name: '月刊テスト'), placed: '')
    Post.create!(content: 'コメント1', topic:, user: users(:two))
    Post.create!(content: 'コメント2', topic:, user: users(:three))
    Post.create!(content: 'コメント3', topic:, user: users(:four))
    Rank.create!(rank: 1, ranking: @kojin, user: users(:one), serie:)
    Rank.create!(rank: 2, ranking: @kojin, user: users(:two), serie:)
    Rank.create!(rank: 1, ranking: @kuso, user: users(:three), serie:)
    serie.rank_info = { rank: 1, sum_of_mark: 7, sum_of_mark_with_kuso: -2,
                        count_rank: 2, count_kuso: 1, count_post: 3 }
    serie.reload.tap { |s| s.rank_info = serie.rank_info }
  end
end
