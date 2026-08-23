module YearlyRanking
  extend ActiveSupport::Concern

  # 年度を表す文字数（name の先頭4文字が西暦という暗黙規約）
  YEAR_LENGTH = 4

  # name の先頭4文字（例: '2015年個人ランキング' → '2015'）を返す
  def year
    name&.slice(0, YEAR_LENGTH)
  end
end
