# ランキング（SerieRanking.aggregate の結果）を XML / JSON / CSV でエクスポートするための整形処理。
module SerieRankingExport
  # CSV のヘッダ行
  CSV_HEADER = %w[順位 合計得点 糞補正後得点 ランキング重複数 糞重複数 コメント数 serie_id name 漫画家 雑誌 ranks].freeze
  # XML のコメント一覧で投稿者名を囲む括弧
  XML_COMMENT_BRACKETS = %w[【 】].freeze
  # JSON のコメント一覧で投稿者名を囲む括弧
  JSON_COMMENT_BRACKETS = %w[（ ）].freeze
  # XML 1.0 で使えない文字（タブ・改行以外の制御文字と U+FFFE / U+FFFF）
  XML_INVALID_CHARS = /[\x00-\x08\x0B\x0C\x0E-\x1F\u{FFFE}\u{FFFF}]/

  class << self
    # XML / JSON 用の 1 作品分の値。
    # detail はレビュー（serie.post）が無ければ空、comments はトピックが無ければ nil。
    def entry(serie, ranking_ids, comment_brackets:)
      {
        rank: "#{serie.rank_info[:rank]}位",
        name: serie.name,
        authors: serie.authors.map(&:name).join('・'),
        ranking: ranking_summary(serie.rank_info),
        magazine: magazine_names(serie),
        detail: detail(serie),
        comments: (comments(serie, ranking_ids, comment_brackets) if serie.topic)
      }
    end

    # ダウンロード時のファイル名。例: 20261031_2025年漫トロ個人ランキング.xml
    def filename(ranking, format)
      "#{Time.zone.today.strftime('%Y%m%d')}_#{ranking.name}.#{format}"
    end

    # 全作品を CSV 文字列にする
    def csv(series, ranking_ids)
      CSV.generate do |csv|
        csv << CSV_HEADER
        series.each { |serie| csv << csv_row(serie, ranking_ids) }
      end
    end

    # 改行と XML 1.0 で使えない制御文字を取り除く。
    # & や < のエスケープは出力側（Haml / Jbuilder）で行うので、ここでは行わない。
    def plain_text(text)
      text.to_s.gsub(/[\r\n]/, '').gsub(XML_INVALID_CHARS, '')
    end

    private

    def ranking_summary(info)
      "（#{info[:sum_of_mark]}点： 得票数#{info[:count_rank]}, " \
        "クソ修正後得点#{info[:sum_of_mark_with_kuso]}点, クソ得票数#{info[:count_kuso]}）"
    end

    # 掲載誌名。掲載位置（placed）があれば「誌名（位置）」にする
    def magazine_names(serie)
      serie.magazines_series.filter_map do |ms|
        next unless ms.magazine

        ms.placed.present? ? "#{ms.magazine.name}（#{ms.placed}）" : ms.magazine.name
      end.uniq.join('　')
    end

    def detail(serie)
      return {} unless serie.post

      { content: plain_text(serie.post.content), by: serie.post.user.name }
    end

    # レビュー以外のトピック投稿を「本文【投稿者:順位】」の形で改行区切りにする
    def comments(serie, ranking_ids, brackets)
      open, close = brackets
      (serie.topic.posts - [serie.post]).map do |post|
        rank = serie.ranks.find { |r| ranking_ids.include?(r.ranking_id) && r.user_id == post.user.id }
        "#{plain_text(post.content)}#{open}#{post.user.name}#{":#{rank_label(rank, ranking_ids)}" if rank}#{close}"
      end.join("\n")
    end

    def csv_row(serie, ranking_ids)
      info = serie.rank_info
      ranks = RankAggregation.sort_ranks(serie.ranks.select { |r| ranking_ids.include?(r.ranking_id) })
      [
        info[:rank], info[:sum_of_mark], info[:sum_of_mark_with_kuso],
        info[:count_rank], info[:count_kuso], info[:count_post],
        serie.id, serie.name,
        serie.authors.map(&:name).join('　'),
        serie.magazines.map(&:name).uniq.join('　'),
        ranks.map { |r| "#{r.user.name} (#{rank_label(r, ranking_ids)})" }.join('　')
      ]
    end

    # 個人ランキングの票なら「1位」、糞ランキングの票なら「糞1位」
    def rank_label(rank, ranking_ids)
      "#{'糞' unless rank.ranking_id == ranking_ids.first}#{rank.rank}位"
    end
  end
end
