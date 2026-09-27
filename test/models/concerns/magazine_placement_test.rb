require 'test_helper'

class MagazinePlacementTest < ActiveSupport::TestCase
  setup do
    @serie = series(:voted_a)
  end

  test '新しい雑誌名を指定すると雑誌ごと作成して掲載誌に追加する' do
    assert_difference ['Magazine.count', 'MagazinesSerie.count'], 1 do
      MagazinePlacement.add!(@serie, magazine_name: '新雑誌', magazine_id: '', placed: '2020年')
    end
    assert_equal '2020年', @serie.reload.magazines_series.last.placed
  end

  test '既存の雑誌名を指定した場合は雑誌を作成せず掲載誌だけ追加する' do
    existing = magazines(:one)
    assert_no_difference 'Magazine.count' do
      assert_difference 'MagazinesSerie.count', 1 do
        MagazinePlacement.add!(@serie, magazine_name: existing.name, magazine_id: '', placed: '2021年')
      end
    end
  end

  test '雑誌IDでも掲載誌を追加できる' do
    assert_difference 'MagazinesSerie.count', 1 do
      MagazinePlacement.add!(@serie, magazine_name: '', magazine_id: magazines(:one).id, placed: '2022年')
    end
  end

  test '同じ雑誌と掲載時期の組み合わせは重複して追加されない' do
    MagazinePlacement.add!(@serie, magazine_name: '', magazine_id: magazines(:one).id, placed: '2022年')
    assert_no_difference 'MagazinesSerie.count' do
      MagazinePlacement.add!(@serie, magazine_name: '', magazine_id: magazines(:one).id, placed: '2022年')
    end
  end

  test '雑誌名も雑誌IDも指定が無い場合はMagazineNotFoundを投げる' do
    assert_raises MagazinePlacement::MagazineNotFound do
      MagazinePlacement.add!(@serie, magazine_name: '', magazine_id: '', placed: '')
    end
  end
end
