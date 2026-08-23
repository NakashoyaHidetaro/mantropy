module PublicIdentifiable
  extend ActiveSupport::Concern

  # 公開URLに使う public_id の文字数
  PUBLIC_ID_LENGTH = 16

  included do
    before_validation :set_public_id
    validates :public_id, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9]+\z/ }
  end

  # 公開ページのURLには内部IDではなく public_id を使う
  def to_param
    public_id
  end

  private

  # public_id が未設定の場合のみランダムな英数字を生成する
  def set_public_id
    self.public_id ||= SecureRandom.alphanumeric(PUBLIC_ID_LENGTH)
  end
end
