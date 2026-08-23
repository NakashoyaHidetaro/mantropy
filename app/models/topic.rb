class Topic < ApplicationRecord
  has_one :book # rubocop:disable Rails/HasManyOrHasOneDependent
  has_one :serie # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :posts # rubocop:disable Rails/HasManyOrHasOneDependent
end
