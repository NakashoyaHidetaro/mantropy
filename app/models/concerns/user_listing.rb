# メンバー一覧の表示対象を「現役メンバー」と「旧メンバー」に振り分けるロジック。
module UserListing
  # この期間内にランキングを提出していれば現役メンバーとみなす
  ACTIVE_RANKING_PERIOD = 1.year
  # この期間内に登録したユーザーは（提出実績が無くても）現役メンバーとみなす
  NEW_MEMBER_PERIOD = 6.months

  class << self
    # 現役メンバー。直近 ACTIVE_RANKING_PERIOD 内に rank を提出したユーザーと、
    # 登録から NEW_MEMBER_PERIOD 以内の新規ユーザーの和集合。
    def active_users
      (
        User.includes(:ranks)
            .where('ranks.created_at > ?', ACTIVE_RANKING_PERIOD.ago)
            .references(:ranks) +
        User.where('created_at > ?', NEW_MEMBER_PERIOD.ago)
      ).uniq
    end

    # 旧メンバー。全ユーザーから現役メンバーを除いたもの。
    # 既に active_users を算出済みなら引数で渡して再計算を避けられる。
    def old_users(active = active_users)
      User.all - active
    end
  end
end
