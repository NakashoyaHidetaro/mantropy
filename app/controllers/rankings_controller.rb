class RankingsController < ApplicationController
  def index
    # 年度ごとのセクションで表示するため、新しい年度が先に来る順序でグルーピングする
    @rankings_by_year = Ranking.order(year: :desc, kind: :asc).group_by(&:year)
  end
end
