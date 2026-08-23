class Serie < ApplicationRecord
  include PublicIdentifiable

  validates :name, presence: true
  has_many :ranks # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :authors_series # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :authors, through: :authors_series
  has_and_belongs_to_many :books, optional: true # rubocop:disable Rails/HasAndBelongsToMany
  has_many :magazines_series # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :magazines, through: :magazines_series
  has_and_belongs_to_many :tags, optional: true # rubocop:disable Rails/HasAndBelongsToMany
  belongs_to :post, optional: true
  belongs_to :topic, optional: true
  has_many :posts, through: :topic

  attr_accessor :rank_info

  # 集計が終了したランキングでの順位のみを、新しいランキング順・上位順に返す。
  # 表示時に rank.ranking / rank.user を参照するためまとめて eager load する。
  def finished_ranks
    ranks.where(ranking_id: Ranking.finished.select(:id))
         .includes(:ranking, :user)
         .order(ranking_id: :desc, rank: :asc)
  end

  # このシリーズの掲示板トピックがまだ無ければ作成して紐づける。
  def ensure_topic!
    return topic if topic

    self.topic = Topic.create!
    save!
    topic
  end
end
