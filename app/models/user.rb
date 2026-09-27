class User < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :realname, presence: true
  validates :mbmail, presence: true
  validates :joined, presence: true
  validates :entered, presence: true
  validate :name_valid?

  has_many :series # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :posts # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :postfavs # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :replies # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :ranks # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :transfers # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :bookreals # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :userauths # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :wikis # rubocop:disable Rails/HasManyOrHasOneDependent

  # ユーザーのURLには内部IDではなく name を使う
  def to_param
    name
  end

  private

  def name_valid?
    errors.add(:name, 'には . # % : \ / を含む文字列は使えません') if name =~ %r{[.\#%:/\\]}
  end
end
