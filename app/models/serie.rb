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
  validates :name, presence: true

  attr_accessor :rank_info
end
