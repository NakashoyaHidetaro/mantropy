# ランキング種別(kind)ごとの見た目(アイコン・配色)を提供するモジュール。
# 一覧のカードグリッド等、複数のビューから同じ配色を使うために切り出している。
module RankingAppearance
  # kind ごとのアイコン(Bootstrap Icons 1.11.3 に実在するもの)と Bootstrap のテーマカラー
  APPEARANCES = {
    'kojin' => { icon: 'bi-trophy-fill', color: 'primary' },
    'kuso' => { icon: 'bi-emoji-dizzy-fill', color: 'warning' },
    'zentai' => { icon: 'bi-stars', color: 'success' },
    'zentaikuso' => { icon: 'bi-fire', color: 'danger' }
  }.freeze

  # 未知の kind に対するフォールバック
  DEFAULT_APPEARANCE = { icon: 'bi-list-ol', color: 'secondary' }.freeze

  class << self
    # kind に対応する見た目のハッシュ({ icon:, color: })
    def for_kind(kind)
      APPEARANCES.fetch(kind.to_s, DEFAULT_APPEARANCE)
    end

    # %i タグに与えるアイコンのクラス文字列(例: 'bi bi-trophy-fill')
    def icon_class(kind)
      "bi #{for_kind(kind)[:icon]}"
    end

    # Bootstrap のテーマカラー名(例: 'primary')
    def color(kind)
      for_kind(kind)[:color]
    end
  end
end
