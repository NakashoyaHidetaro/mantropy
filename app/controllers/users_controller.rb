class UsersController < ApplicationController
  def index
    @users = UserListing.active_users
    @old_users = UserListing.old_users(@users)
    @registering_rankings = registering_rankings
    @display_rankings = if @registering_rankings.empty?
                          Ranking.of_year(Time.zone.now.year, kind: %w[kojin kuso])
                        else
                          @registering_rankings
                        end
    @downloadable = member_list_downloadable?(@registering_rankings)

    respond_to do |format|
      format.html # index.html.erb
      format.csv if @downloadable
      format.json if @downloadable
    end
  end

  def show
    @user = User.find_by(name: params.expect(:name))
    return redirect_to users_path, notice: '存在しないユーザーです' if @user.blank?

    @registerable_rankings = registerable_rankings
    @registering_rankings = registering_rankings
    @registering_years = @registering_rankings.map(&:year).uniq
    @show_registering_ranks = show_registering_ranks?
    @ranks_by_year = RankAggregation.ranks_by_year(
      @user, excluded_years: @show_registering_ranks ? [] : @registering_years
    )
    # 非ログインユーザーには内部掲示板の書き込みを見せない
    @posts = PostTimeline.recent_user_posts(@user, include_board: current_user.present?)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @user }
      format.csv  { render csv: @user }
    end
  end

  private

  # 集計中（登録受付中）の年度のランキングを閲覧できるか
  # 本人、または今年の個人ランキングを提出完了済みのログインユーザーのみ許可する
  def show_registering_ranks?
    return false if @registering_rankings.empty?
    return true if current_user == @user

    kojin = @registering_rankings.select(&:kojin?).min_by(&:id) ||
            @registering_rankings.min_by(&:id)
    current_user.present? && complete_ranking(kojin)
  end
end
