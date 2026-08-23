# 検索フォームから渡された文字列でシリーズを検索する。
# 検索文字列は空白区切りで複数語に分割し、各語について
# 「シリーズ名に一致」または「そのシリーズの著者名に一致」を条件とし、
# 複数語は AND（すべての語に一致するシリーズのみ）で絞り込む。
module SerieSearch
  # 検索語の区切りとして扱う文字（半角・全角スペース）
  WORD_SEPARATOR = /[[:space:]　]/

  # シリーズ名の検索対象カラム（将来 name_kana 等が増えたらここに追加する）
  SERIE_SEARCH_COLUMNS = %w[name].freeze
  # 著者名の検索対象カラム
  AUTHOR_SEARCH_COLUMNS = %w[name].freeze

  class << self
    # 検索文字列にマッチするシリーズを、ページング済みの relation で返す。
    # 一覧表示で serie.books を参照するため books を eager load しておく。
    def search(str, page: nil)
      scope = Serie.all
      words(str).each do |word|
        scope = scope.where(id: matches_word(word).select(:id))
      end
      scope.includes(:books).order(id: :desc).page(page)
    end

    # 検索文字列を半角／全角スペースで分割し、空要素を除いた検索語の配列を返す。
    def words(str)
      str.to_s.strip.split(WORD_SEPARATOR).compact_blank
    end

    private

    # 1つの検索語にマッチするシリーズの relation を返す。
    # シリーズ名そのもの、またはそのシリーズに紐づく著者名のいずれかに一致すればよい。
    def matches_word(word)
      Serie.where(like_condition(Serie, SERIE_SEARCH_COLUMNS), q: like_pattern(word))
           .or(Serie.where(id: serie_ids_by_author(word)))
    end

    # 検索語にマッチする著者が持つシリーズの id を引く relation を返す。
    def serie_ids_by_author(word)
      author_ids = Author.where(like_condition(Author, AUTHOR_SEARCH_COLUMNS), q: like_pattern(word)).select(:id)
      AuthorsSerie.where(author_id: author_ids).select(:serie_id)
    end

    # 指定カラムのいずれかが LIKE にマッチする、という SQL 断片を組み立てる。
    def like_condition(model, columns)
      columns.map { |column| "#{model.quoted_table_name}.#{model.connection.quote_column_name(column)} LIKE :q" }
             .join(' OR ')
    end

    # 部分一致用の LIKE パターン。
    def like_pattern(word)
      "%#{ActiveRecord::Base.sanitize_sql_like(word)}%"
    end
  end
end
