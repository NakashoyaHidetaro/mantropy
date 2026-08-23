class AddPublicIdToSeries < ActiveRecord::Migration[8.1]
  # バックフィル専用のローカルモデル（アプリ側のバリデーションを避ける）
  class MigrationSerie < ActiveRecord::Base
    self.table_name = 'series'
  end

  def up
    add_column :series, :public_id, :string

    MigrationSerie.reset_column_information
    MigrationSerie.where(public_id: nil).find_each do |serie|
      serie.update_column(:public_id, SecureRandom.alphanumeric(16)) # rubocop:disable Rails/SkipsModelValidations
    end

    change_column_null :series, :public_id, false
    add_index :series, :public_id, unique: true
  end

  def down
    remove_index :series, :public_id
    remove_column :series, :public_id
  end
end
