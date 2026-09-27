# モデル側で必須（presence バリデーション、または optional でない belongs_to）なのに
# DB 側に NOT NULL 制約が無いカラムへ、まとめて制約を付ける。
#
# rankings.scope_max 以外のカラムは本番で NULL 0 件を確認済み（2026-09-28）。
# rankings.scope_max だけは NULL が残っているため、up の中でバックフィルしてから制約を付ける。
class AddNotNullConstraintsToLegacyTables < ActiveRecord::Migration[8.1]
  # 制約を付ける対象。テーブル名 => カラム名の配列
  TARGET_COLUMNS = {
    rankings: %i[scope_min scope_max created_at updated_at],
    series: %i[name],
    users: %i[name realname mbmail joined entered],
    books: %i[name],
    authors: %i[name],
    magazines: %i[name],
    tags: %i[name],
    posts: %i[content topic_id],
    wikis: %i[name title content user_id],
    ranks: %i[ranking_id serie_id user_id],
    authors_books: %i[author_id book_id],
    authors_series: %i[author_id serie_id],
    books_series: %i[book_id serie_id],
    series_tags: %i[serie_id tag_id]
  }.freeze

  def up
    backfill_rankings_scope_max
    each_target { |table, column| change_column_null(table, column, false) }
  end

  def down
    each_target { |table, column| change_column_null(table, column, true) }
  end

  private

  def each_target
    TARGET_COLUMNS.each do |table, columns|
      columns.each { |column| yield(table, column) }
    end
  end

  # scope_max が未設定のランキングは、集計済み Rank の最大順位で埋める。
  # Rank が1件も無い場合は scope_min（それも無ければ 1）で代替する。
  def backfill_rankings_scope_max
    execute <<~SQL.squish
      UPDATE rankings
      SET scope_max = COALESCE(
        (SELECT MAX(ranks.rank) FROM ranks WHERE ranks.ranking_id = rankings.id),
        rankings.scope_min,
        1
      )
      WHERE rankings.scope_max IS NULL
    SQL
  end
end
