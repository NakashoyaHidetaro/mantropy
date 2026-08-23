class Rankings::SeriesController < Rankings::Base
  def index
    pair = SerieRanking.ranking_pair(@ranking)
    ranking_plus, ranking_minus = pair
    return redirect_to(aggregated_ranking_series_path(@ranking)) if pair.nil? || ranking_plus.blank?

    notice = SerieRanking.restriction_notice(@ranking, current_user)
    return redirect_to(rankings_path, notice:) if notice.present?

    @ranking_ids = [ranking_plus.id, ranking_minus&.id]
    @series = SerieRanking.aggregate(ranking_plus, ranking_minus, sort_by_kuso: @ranking == ranking_minus)
    @is_should_comment_term = ranking_plus.finished? && (ranking_minus.nil? || ranking_minus.finished?)
    # 同じ年度の集計済みランキング（個人・糞以外）。集計ページへの導線として表示する。
    @aggregated_rankings = Ranking.same_year_as(@ranking).aggregated
    @series = Kaminari.paginate_array(@series).page(params[:page]).per(SerieRanking::PER_PAGE)

    @downloadable = SerieRanking.downloadable?(current_user)

    respond_to do |format|
      format.html
      format.csv if @downloadable
      format.xml { @series = @series[0...SerieRanking::EXPORT_LIMIT] } if @downloadable
      format.json { @series = @series[0...SerieRanking::EXPORT_LIMIT] } if @downloadable
    end
  end

  def aggregated
    # 同年度の各 kind のランキング。順位・得点・投票者リストをどの ranking から引くかに使う
    @rankings_by_kind = SerieRanking.same_year_rankings_by_kind(@ranking)
    @series = Kaminari.paginate_array(SerieRanking.aggregated_series(@ranking).to_a).page(params[:page])
  end
end
