class Rankings::Base < ApplicationController
  before_action :set_ranking

  private

  # URL の :ranking_id は "2024-all" 形式の slug
  def set_ranking
    @ranking = Ranking.find_by_slug(params[:ranking_id])

    redirect_to(rankings_path, notice: 'ランキングが存在しません') if @ranking.nil?
  end
end
