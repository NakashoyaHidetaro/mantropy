module YearlyRanking
  extend ActiveSupport::Concern

  # 年度を表す文字数（name の先頭4文字が西暦という暗黙規約）
  YEAR_LENGTH = 4

  # name の先頭4文字（例: '2015年個人ランキング' → '2015'）を返す
  def year
    name&.slice(0, YEAR_LENGTH)
  end

  class_methods do
    # 指定年度（西暦4文字）に属するランキング群。
    # kind を渡すと種別（'kojin' / 'kuso' など。配列も可）で絞り込む。
    def of_year(year, kind: nil)
      relation = where(['name LIKE ?', "#{year}%"])
      kind.nil? ? relation : relation.where(kind: kind)
    end

    # 基準となるランキングと同じ年度のランキング群。
    def same_year_as(ranking, kind: nil)
      of_year(ranking.year, kind: kind)
    end
  end
end
