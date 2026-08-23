module YearlyRanking
  extend ActiveSupport::Concern

  class_methods do
    # 指定年度（西暦）に属するランキング群。
    # kind を渡すと種別（'kojin' / 'kuso' など。配列も可）で絞り込む。
    def of_year(year, kind: nil)
      relation = where(year: year.to_i)
      kind.nil? ? relation : relation.where(kind: kind)
    end

    # 基準となるランキングと同じ年度のランキング群。
    def same_year_as(ranking, kind: nil)
      of_year(ranking.year, kind: kind)
    end
  end
end
