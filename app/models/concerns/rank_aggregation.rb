# ランキング集計まわりの共通ロジック。
# 順位の付与（同点は同順位）、ranks の並び替え、年度ごとの集約、提出完了判定を担う。
module RankAggregation
  class << self
    # 集計済みの Serie 配列（既に順位順に並んでいる前提）へ rank_info[:rank] を付与する。
    # keys で指定した rank_info の値がすべて直前と等しければ同順位とし、
    # 異なれば「その時点での通し番号」を順位とする（同順位が続いた分は飛び番になる）。
    def assign_ranks(series, keys:)
      position = 0
      rank = 0
      previous = nil
      series.each do |serie|
        position += 1
        current = keys.map { |key| serie.rank_info[key] }
        rank = position unless current == previous
        serie.rank_info[:rank] = rank
        previous = current
      end
      series
    end

    # ranks をランキングID順、同一ランキング内では順位順に並べ替える。
    def sort_ranks(ranks)
      ranks.sort do |a, b|
        (a.ranking_id <=> b.ranking_id).nonzero? || (a.rank.to_i <=> b.rank.to_i)
      end
    end

    # ユーザーの ranks を年度（降順）ごとにまとめて返す。
    # excluded_years に含まれる年度（集計中で閲覧権限が無い年度など）は除外する。
    def ranks_by_year(user, excluded_years: [])
      ranks = user.ranks.includes(:ranking, serie: [:authors, { magazines_series: :magazine }]).to_a
      grouped = ranks.group_by { |rank| rank.ranking.year }
      grouped = grouped.except(*excluded_years) if excluded_years.present?
      grouped.sort_by { |year, _| year.to_s }.reverse.to_h.transform_values { |list| sort_ranks(list) }
    end

    # そのランキングへユーザーが規定の順位をすべて提出し終えているか。
    def complete_ranking?(ranking, user)
      return false if user.blank?

      submitted = user.ranks.where(ranking_id: ranking.id).map { |r| r.serie ? r.rank : 0 }
      submitted.sort == ((ranking.scope_min)..(ranking.scope_max)).to_a
    end
  end
end
