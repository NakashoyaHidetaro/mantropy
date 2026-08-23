class Ranking < ApplicationRecord
  include YearlyRanking

  # 新規ランキング作成フォームの初期値に使う集計終了日(月・日)
  DEFAULT_AGGREGATION_END_MONTH_DAY = [11, 20].freeze
  # 新規ランキング作成フォームの初期値に使う一般公開日(月・日)
  DEFAULT_PUBLICATION_MONTH_DAY = [12, 31].freeze
  # kind ごとのURLスラッグ(to_param は "#{year}-#{slug}" 形式)
  KIND_SLUGS = { 'kojin' => 'all', 'kuso' => 'kuso', 'zentai' => 'zentai', 'zentaikuso' => 'zentai-kuso' }.freeze
  # kind ごとの表示名(name カラム廃止に伴い year + これで表示名を生成)
  KIND_NAMES = { 'kojin' => '漫トロ個人ランキング', 'kuso' => '漫トロ個人クソランキング',
                 'zentai' => '漫トロピー漫画ランキング', 'zentaikuso' => '漫トロピークソ漫画ランキング' }.freeze

  enum :kind, { kojin: 0, kuso: 1, zentai: 2, zentaikuso: 3 }

  has_many :ranks, dependent: :destroy

  validates :year, :aggregation_ends_on, :published_on, presence: true
  validates :year, uniqueness: { scope: :kind }

  # 投票受付中(集計中)のランキング。集計終了日当日はまだ受付中とみなす。
  scope :registerable, -> { where(aggregation_ends_on: Date.current..) }
  # 集計が終了し、結果を表示してよいランキング
  scope :finished, -> { where(aggregation_ends_on: ...Date.current) }
  # 個人・クソ以外の、集計済み結果を保持する全体集計ランキング
  scope :aggregated, -> { where(kind: %i[zentai zentaikuso]) }

  # to_param 形式のスラッグ("2024-all" 等)から該当ランキングを引く。
  # 形式不正・該当なしの場合は nil を返す。
  def self.find_by_slug(param)
    year, slug = param.to_s.split('-', 2)
    return nil if year.blank? || slug.blank? || !year.match?(/\A[0-9]{4}\z/)

    kind = KIND_SLUGS.key(slug)
    return nil if kind.nil?

    find_by(year: year.to_i, kind: kind)
  end

  # 表示名(例: '2024年漫トロ個人ランキング')
  def name
    "#{year}年#{KIND_NAMES[kind]}"
  end

  # 年度を含まない種別の表示名(例: '漫トロ個人ランキング')
  def kind_name
    KIND_NAMES[kind]
  end

  # 種別ごとのアイコンクラス(例: 'bi bi-trophy-fill')
  def icon_class
    RankingAppearance.icon_class(kind)
  end

  # 種別ごとの Bootstrap テーマカラー名(例: 'primary')
  def theme_color
    RankingAppearance.color(kind)
  end

  def to_param
    "#{year}-#{KIND_SLUGS[kind]}"
  end

  # 投票受付中(集計中)か。集計終了日当日はまだ受付中。
  def registerable?
    Date.current <= aggregation_ends_on
  end

  def finished?
    !registerable?
  end

  # 一般公開済みか。公開日当日から公開扱い。
  def published?
    Date.current >= published_on
  end
end
