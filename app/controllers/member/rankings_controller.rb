class Member::RankingsController < Member::Base
  before_action :admin_basic_authentication
  before_action :set_ranking, only: %i[update]

  def index
    @rankings = Ranking.order(:name)
    @new_ranking = Ranking.new
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

  def set_ranking
    @ranking = Ranking.find(params[:id])
  end

  def ranking_params
    params.expect(
      ranking: %i[name
                  is_registerable
                  scope_min
                  scope_max
                  kind]
    )
  end
end
