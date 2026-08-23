class Ranking < ApplicationRecord
  include YearlyRanking

  validates :name, presence: true
  has_many :ranks, dependent: :destroy
end
