# ランキングの提出状況にもとづく閲覧・ダウンロード可否の判定をまとめたモジュール。
# コントローラ・ビューの双方から参照する。
module RankingSubmission
  class << self
    # メンバー一覧の CSV / JSON をダウンロードできるか。
    # ログイン済みで、かつ集計中（登録受付中）の年度が無いか、
    # 集計中年度の先頭ランキングを提出完了していること。
    def member_list_downloadable?(user, registering_rankings = nil)
      return false if user.blank?
      return true if Ranking.registerable.empty?

      rankings = registering_rankings.presence || self.registering_rankings
      RankAggregation.complete_ranking?(rankings.first, user)
    end

    # 集計中の年度に属するランキング群（受付中のものが無ければ空）
    def registering_rankings
      registerable = Ranking.registerable
      return [] if registerable.empty?

      Ranking.same_year_as(registerable.last).order(:id)
    end
  end
end
