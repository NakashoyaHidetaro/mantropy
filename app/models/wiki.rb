class Wiki < ApplicationRecord
  belongs_to :user
  validates :name, presence: true
  validates :title, presence: true
  validates :content, presence: true
  validate :name_valid?

  private

  def name_valid?
    errors.add(:name, 'には、小文字半角英数字とアンダーバーのみ使えます') unless name =~ /^[0-9a-z_]+$/
  end
end
