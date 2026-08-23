class Member::HomesController < Member::Base
  def index
    @wiki = Wiki.where(name: 'logged_in').order(created_at: :desc).limit(1).first
    @wikis = Wiki.where(name: @wiki&.name).order(created_at: :desc)
    # 集計データへの導線として全ランキングを新しい順に列挙する
    @rankings = Ranking.order(id: :desc)
  end
end
