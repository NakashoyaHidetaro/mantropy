class Ranking < ApplicationRecord
  include YearlyRanking

  validates :name, presence: true
  has_many :ranks, dependent: :destroy

  # 集計中(投票受付中)のランキング
  scope :registerable, -> { where(is_registerable: true) }
  # 集計が終了し、結果を表示してよいランキング
  scope :finished, -> { where(is_registerable: [nil, false]) }
  # 個人・糞以外の、集計済み結果を保持するランキング
  # (Rankings::SeriesController#index はこの種別を aggregated へリダイレクトする)
  scope :aggregated, -> { where(kind: nil).or(where.not(kind: %w[kojin kuso])) }
end
