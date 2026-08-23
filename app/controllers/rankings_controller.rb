class RankingsController < ApplicationController
  def index
    @rankings = Ranking.order(year: :desc, kind: :asc)
  end
end
