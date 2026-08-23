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
    @registering_years = @registering_rankings.map(&:year).uniq
    @show_registering_ranks = show_registering_ranks?
    @ranks_by_year = ranks_by_year_for(@user)

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

    kojin = @registering_rankings.select { |r| r.kind == 'kojin' }.min_by(&:id) ||
            @registering_rankings.min_by(&:id)
    current_user.present? && complete_ranking(kojin)
  end

  # 年度（降順）ごとにまとめた ranks を返す。集計中年度は閲覧権限が無ければ除外する
  def ranks_by_year_for(user)
    ranks = user.ranks.includes(:ranking, serie: [:authors, { magazines_series: :magazine }]).to_a
    grouped = ranks.group_by { |rank| rank.ranking.year }
    grouped = grouped.except(*@registering_years) unless @show_registering_ranks
    grouped.sort_by { |year, _| year.to_s }.reverse.to_h.transform_values do |list|
      list.sort do |a, b|
        (a.ranking_id <=> b.ranking_id).nonzero? || (a.rank.to_i <=> b.rank.to_i)
      end
    end
  end
end
