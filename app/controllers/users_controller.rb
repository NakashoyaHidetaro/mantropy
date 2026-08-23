class UsersController < ApplicationController
  def index
    @title = 'メンバー一覧'
    @users = (
      User.includes(:ranks).where('ranks.created_at > ?', 1.year.ago).references(:ranks) +
      User.where('created_at > ?', 6.months.ago)
    ).uniq
    @old_users = User.all - @users
    @registering_rankings = registering_rankings
    @display_rankings = if @registering_rankings.empty?
                          Ranking.where('name LIKE ? AND (kind = ? OR kind = ?)',
                                        "#{Time.zone.now.year}%", 'kojin', 'kuso')
                        else
                          @registering_rankings
                        end

    respond_to do |format|
      format.html # index.html.erb
      format.csv if current_user && (registerable_rankings.empty? || complete_ranking(@registering_rankings.first))
      format.json if current_user && (registerable_rankings.empty? || complete_ranking(@registering_rankings.first))
    end
  end

  def show
    @user = User.find_by(name: params.expect(:name))
    return redirect_to users_path, notice: '存在しないユーザーです' if @user.blank?

    @title = @user.name.to_s
    @registerable_rankings = registerable_rankings
    @registering_rankings = registering_rankings
    list_rankings = @registerable_rankings.empty? ? Ranking.all : registering_rankings
    @ranks = @user.ranks.where(ranking_id: list_rankings).sort do |a, b|
      (a.ranking_id <=> b.ranking_id).nonzero? or a.rank <=> b.rank
    end
    @do_show_ranking = current_user == @user ||
                       (current_user && (@registerable_rankings.empty? ||
                        complete_ranking(@registering_rankings.order(:id).first)))

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @user }
      format.csv  { render csv: @user }
    end
  end
end
