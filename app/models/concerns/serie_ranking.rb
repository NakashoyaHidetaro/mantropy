# 個人ランキング（kojin）と糞ランキング（kuso）の投票を漫画（Serie）ごとに集計する。
# 集計結果は Serie#rank_info（Hash）へ Integer で詰めて返す。
module SerieRanking # rubocop:disable Metrics/ModuleLength
  # 重複投票ボーナス: 2人目以降の投票者1人につき加算する点数
  DUPLICATE_BONUS = 3
  # 糞ランキングのマイナス点倍率
  KUSO_MULTIPLIER = 2
  # 糞ランキングの重複投票ペナルティ（2人目以降1人につき）
  KUSO_DUPLICATE_PENALTY = -3
  # ランキング一覧の1ページあたり件数
  PER_PAGE = 64
  # XML/JSON エクスポートの最大件数
  EXPORT_LIMIT = 56
  # この順位以内はコメント必須
  COMMENT_REQUIRED_RANK = 50
  # この順位以内は書影画像を表示する
  IMAGE_RANK_LIMIT = 30

  # 一覧表示で参照する関連。N+1 を避けるためまとめて preload する。
  PRELOAD_ASSOCIATIONS = [
    :authors,
    :magazines,
    { magazines_series: :magazine },
    { ranks: :user },
    { post: :user },
    { topic: { posts: :user } },
    { posts: :user }
  ].freeze

  # 集計済みランキング（aggregated）の一覧で参照する関連。
  AGGREGATED_PRELOAD_ASSOCIATIONS = %i[authors magazines].freeze

  class << self # rubocop:disable Metrics/ClassLength
    # ranking から（プラス側, マイナス側）のペアを返す。
    # kind が 'kojin' なら [ranking, 同年度の kuso の最後]、'kuso' なら [同年度の kojin の最後, ranking]。
    # それ以外の kind は nil を返す（呼び出し側でリダイレクトする）。
    def ranking_pair(ranking)
      case ranking&.kind
      when 'kojin'
        [ranking, Ranking.same_year_as(ranking, kind: 'kuso').last]
      when 'kuso'
        [Ranking.same_year_as(ranking, kind: 'kojin').last, ranking]
      end
    end

    # ランキングを閲覧できない場合のメッセージを返す（閲覧できるなら nil）。
    # 集計中（投票受付中）は誰にも見せず、集計終了後・一般公開日前はメンバーのみに見せる。
    def restriction_notice(ranking, user)
      if ranking.registerable?
        'ランキングは集計中なので誰も見れないよ'
      elsif !ranking.published? && user.blank?
        'ランキングは集計中なのでメンバーだけが見れるよ'
      end
    end

    # ランキングの XML/CSV/JSON をダウンロードできるか。ログイン中のユーザーのみ許可する。
    def downloadable?(user)
      user.present?
    end

    # 集計本体。ranking_plus は必須、ranking_minus は nil 可（nil なら糞補正なし＝0扱い）。
    # sort_by_kuso: true なら補正後合計点を第一ソートキーにする（糞ランキング表示用）。
    # 戻り値は順位順に並んだ Serie の配列で、各要素の rank_info に集計値が入る。
    def aggregate(ranking_plus, ranking_minus, sort_by_kuso: false)
      return [] if ranking_plus.blank?

      rows = aggregate_rows(ranking_plus, ranking_minus, sort_by_kuso:)
      series = series_in_order(rows)
      keys = sort_by_kuso ? %i[sum_of_mark_with_kuso count_kuso min_rank] : %i[sum_of_mark count_rank min_rank]
      RankAggregation.assign_ranks(series, keys:)
    end

    # 指定ランキングと同年度のランキングを kind（文字列）をキーにした Hash で返す。
    # 全体集計ページで kojin / kuso / zentai / zentaikuso の各ランキングを引くのに使う。
    def same_year_rankings_by_kind(ranking)
      return {} if ranking.blank?

      Ranking.same_year_as(ranking).index_by(&:kind)
    end

    # aggregated アクション用: ranking の rank 順の Serie 一覧。
    def aggregated_series(ranking)
      Serie.joins(:ranks)
           .where(ranks: { ranking_id: ranking.id })
           .preload(AGGREGATED_PRELOAD_ASSOCIATIONS)
           .order('ranks.rank')
    end

    private

    # 集計 SQL を実行し、serie_id と集計値の Hash の配列を順位順で返す。
    def aggregate_rows(ranking_plus, ranking_minus, sort_by_kuso:)
      sql = <<~SQL.squish
        SELECT s.id AS serie_id,
               rs.mark AS sum_of_mark,
               (rs.mark + COALESCE(rk.mark, 0)) AS sum_of_mark_with_kuso,
               rs.count_rank AS count_rank,
               rk.count_kuso AS count_kuso,
               pc.count_post AS count_post,
               rs.min_rank AS min_rank
        FROM series s
        INNER JOIN (#{plus_subquery(ranking_plus)}) rs ON s.id = rs.serie_id
        LEFT JOIN (#{minus_subquery(ranking_minus)}) rk ON s.id = rk.serie_id
        LEFT JOIN (#{post_count_subquery(ranking_plus)}) pc ON s.topic_id = pc.topic_id
        ORDER BY #{order_clause(sort_by_kuso:)}
      SQL

      ActiveRecord::Base.connection.select_all(sql).map do |row|
        {
          serie_id: row['serie_id'].to_i,
          sum_of_mark: row['sum_of_mark'].to_i,
          sum_of_mark_with_kuso: row['sum_of_mark_with_kuso'].to_i,
          count_rank: row['count_rank'].to_i,
          count_kuso: row['count_kuso'].to_i,
          count_post: row['count_post'].to_i,
          min_rank: row['min_rank'].to_i
        }
      end
    end

    # 集計結果の順序どおりに Serie を並べ、rank_info を詰めて返す。
    def series_in_order(rows)
      series_by_id = Serie.where(id: rows.pluck(:serie_id))
                          .preload(PRELOAD_ASSOCIATIONS)
                          .index_by(&:id)
      rows.filter_map do |row|
        serie = series_by_id[row[:serie_id]]
        next if serie.nil?

        serie.rank_info = row.except(:serie_id)
        serie
      end
    end

    # プラス側（個人ランキング）の漫画ごとの集計。
    # 得点 = SUM(満点 - 順位) + （投票者数 - 1）× 重複ボーナス
    def plus_subquery(ranking)
      Rank.where(ranking_id: ranking.id)
          .group(:serie_id)
          .select(
            'serie_id',
            Rank.sanitize_sql_array(
              ['(SUM(? - rank) + ((COUNT(*) - 1) * ?)) AS mark', ranking.scope_max + 1, DUPLICATE_BONUS]
            ),
            'COUNT(id) AS count_rank',
            'MIN(rank) AS min_rank'
          ).to_sql
    end

    # マイナス側（糞ランキング）の漫画ごとの集計。ランキングが無い場合は空集合を返す。
    # 補正点 = SUM(順位 - 満点) × 倍率 + （投票者数 - 1）× 重複ペナルティ
    def minus_subquery(ranking)
      return 'SELECT NULL::integer AS serie_id, NULL::integer AS mark, NULL::integer AS count_kuso WHERE false' if
        ranking.blank?

      Rank.where(ranking_id: ranking.id)
          .group(:serie_id)
          .select(
            'serie_id',
            Rank.sanitize_sql_array(
              ['((SUM(rank - ?) * ?) + ((COUNT(*) - 1) * ?)) AS mark',
               ranking.scope_max + 1, KUSO_MULTIPLIER, KUSO_DUPLICATE_PENALTY]
            ),
            'COUNT(id) AS count_kuso'
          ).to_sql
    end

    # ランキング作成日時より後に投稿されたコメント数をトピックごとに数える。
    def post_count_subquery(ranking)
      Post.where('posts.created_at > ?', ranking.created_at)
          .group(:topic_id)
          .select('topic_id', 'COUNT(id) AS count_post')
          .to_sql
    end

    # 並び順。糞票数は未投票（NULL）を末尾に置く。
    def order_clause(sort_by_kuso:)
      first_key = sort_by_kuso ? '(rs.mark + COALESCE(rk.mark, 0))' : 'rs.mark'
      "#{first_key} DESC, rs.count_rank DESC, rs.min_rank ASC, rk.count_kuso ASC NULLS LAST"
    end
  end
end
