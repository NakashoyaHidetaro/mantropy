class Member::RankingsController < Member::Base
  before_action :admin_basic_authentication
  before_action :set_ranking, only: %i[update]

  def index
    @rankings = Ranking.order(:year, :kind)
    @new_ranking = Ranking.new(
      year: Date.current.year,
      aggregation_ends_on: default_date(Ranking::DEFAULT_AGGREGATION_END_MONTH_DAY),
      published_on: default_date(Ranking::DEFAULT_PUBLICATION_MONTH_DAY)
    )
  end

  def create
    @ranking = Ranking.new(ranking_params)
    @ranking.save!
    redirect_to member_rankings_path
  end

  def update
    @ranking.update!(ranking_params)
    redirect_to member_rankings_path
  end

  private

  # to_param が slug（"2015-all" 形式）なので URL の :id も slug で来る
  def set_ranking
    @ranking = Ranking.find_by_slug(params[:id])
    raise ActiveRecord::RecordNotFound if @ranking.nil?
  end

  # [月, 日] の定数から今年の日付を組み立てる
  def default_date(month_day)
    Date.new(Date.current.year, *month_day)
  end

  def ranking_params
    params.expect(
      ranking: %i[year
                  kind
                  scope_min
                  scope_max
                  aggregation_ends_on
                  published_on]
    )
  end
end
