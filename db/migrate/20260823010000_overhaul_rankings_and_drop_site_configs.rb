# ランキングの再設計。
# 1. ranks / posts に集計高速化用のインデックスを追加する
# 2. rankings の name（先頭4文字が年度という暗黙規約）を year カラムへ、
#    kind を string から integer enum へ、公開制御を SiteConfig から
#    aggregation_ends_on / published_on の2つの日付カラムへ移す
# 3. 上記により唯一の用途を失った site_configs テーブルを削除する
class OverhaulRankingsAndDropSiteConfigs < ActiveRecord::Migration[8.1]
  # kind の文字列値と enum の整数値の対応
  KIND_MAPPING = { 'kojin' => 0, 'kuso' => 1, 'zentai' => 2, 'zentaikuso' => 3 }.freeze

  def up
    add_aggregation_indexes
    migrate_year
    migrate_kind_to_enum
    add_schedule_columns
    remove_legacy_columns
    add_index :rankings, %i[year kind], unique: true, if_not_exists: true
    drop_table :site_configs
  end

  def down
    create_site_configs
    remove_index :rankings, %i[year kind], if_exists: true
    restore_legacy_columns
    restore_kind_to_string
    remove_column :rankings, :published_on
    remove_column :rankings, :aggregation_ends_on
    remove_column :rankings, :year
    remove_aggregation_indexes
  end

  private

  # --- up ---

  # 集計クエリ（ranks の集計と posts のコメント数集計）を高速化するインデックス
  def add_aggregation_indexes
    add_index :ranks, %i[ranking_id serie_id], if_not_exists: true
    add_index :ranks, :serie_id, if_not_exists: true
    add_index :ranks, :user_id, if_not_exists: true
    add_index :posts, :topic_id, if_not_exists: true
  end

  # name の先頭4文字から year を埋める。数字4桁で始まらない場合は
  # created_at の年、それも無ければ現在の年で代替する。
  def migrate_year
    add_column :rankings, :year, :integer
    execute <<~SQL.squish
      UPDATE rankings
      SET year = COALESCE(
        NULLIF(substring(name from '^[0-9]{4}'), '')::integer,
        EXTRACT(YEAR FROM created_at)::integer,
        EXTRACT(YEAR FROM CURRENT_DATE)::integer
      )
    SQL
    change_column_null :rankings, :year, false
  end

  # 一時カラムへ整数値を詰め替えてから旧カラムを差し替える
  def migrate_kind_to_enum
    add_column :rankings, :kind_enum, :integer
    execute <<~SQL.squish
      UPDATE rankings SET kind_enum = CASE kind
        #{KIND_MAPPING.map { |name, value| "WHEN '#{name}' THEN #{value}" }.join(' ')}
        ELSE 0 END
    SQL
    remove_column :rankings, :kind
    rename_column :rankings, :kind_enum, :kind
    change_column_null :rankings, :kind, false
  end

  # 集計終了日は 11/20、一般公開日は 12/31 を既定値として埋める
  def add_schedule_columns
    add_column :rankings, :aggregation_ends_on, :date
    add_column :rankings, :published_on, :date
    execute <<~SQL.squish
      UPDATE rankings
      SET aggregation_ends_on = make_date(year, 11, 20),
          published_on = make_date(year, 12, 31)
    SQL
    change_column_null :rankings, :aggregation_ends_on, false
    change_column_null :rankings, :published_on, false
  end

  def remove_legacy_columns
    remove_column :rankings, :name
    remove_column :rankings, :is_registerable
  end

  # --- down ---

  def create_site_configs
    create_table :site_configs do |t|
      t.string :path, null: false
      t.string :name, null: false
      t.string :value, null: false
      t.timestamps
      t.index :path
    end
  end

  # name は「YYYY年」＋種別名で復元する（元の文言とは一致しない）
  def restore_legacy_columns
    add_column :rankings, :name, :string
    add_column :rankings, :is_registerable, :boolean
    execute <<~SQL.squish
      UPDATE rankings SET name = year::text || '年' || CASE kind
        #{KIND_MAPPING.map { |name, value| "WHEN #{value} THEN '#{name}'" }.join(' ')}
        ELSE '' END,
        is_registerable = (aggregation_ends_on >= CURRENT_DATE)
    SQL
  end

  def restore_kind_to_string
    add_column :rankings, :kind_string, :string
    execute <<~SQL.squish
      UPDATE rankings SET kind_string = CASE kind
        #{KIND_MAPPING.map { |name, value| "WHEN #{value} THEN '#{name}'" }.join(' ')}
        ELSE NULL END
    SQL
    remove_column :rankings, :kind
    rename_column :rankings, :kind_string, :kind
  end

  def remove_aggregation_indexes
    remove_index :posts, :topic_id, if_exists: true
    remove_index :ranks, :user_id, if_exists: true
    remove_index :ranks, :serie_id, if_exists: true
    remove_index :ranks, %i[ranking_id serie_id], if_exists: true
  end
end
