# シリーズへの掲載誌(雑誌 + 掲載時期)の追加をまとめて扱う。
# 雑誌は名前かIDで特定し、見つからなければ新規作成する。
module MagazinePlacement
  # 雑誌名も雑誌IDも指定されておらず、雑誌を特定できなかった場合に投げる。
  class MagazineNotFound < StandardError; end

  class << self
    # シリーズに掲載誌を追加する。
    # すでに同じ雑誌・同じ掲載時期の掲載誌があれば何もしない。
    # 雑誌を特定できない場合は MagazineNotFound、
    # バリデーションに失敗した場合は ActiveRecord::RecordInvalid を投げる。
    def add!(serie, magazine_name:, magazine_id:, placed:)
      magazine = find_or_create_magazine!(serie, magazine_name.to_s.strip, magazine_id)
      raise MagazineNotFound unless magazine

      placed = placed.to_s.strip
      return nil if serie.magazines_series.exists?(magazine_id: magazine.id, placed:)

      MagazinesSerie.create!(magazine:, placed:, serie:)
    end

    private

    def find_or_create_magazine!(serie, name, id)
      found = (name.empty? ? nil : Magazine.find_by(name:)) || Magazine.find_by(id:)
      return found if found
      return nil if name.empty?

      Magazine.create!(name:, publisher: serie.books.first&.publisher)
    end
  end
end
