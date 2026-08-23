require 'test_helper'

class PublicIdentifiableTest < ActiveSupport::TestCase
  test '保存時に public_id が自動生成される（16桁の英数字）' do
    serie = Serie.create!(name: 'テスト作品')
    assert_equal PublicIdentifiable::PUBLIC_ID_LENGTH, serie.public_id.length
    assert_match(/\A[a-zA-Z0-9]{16}\z/, serie.public_id)
  end

  test '明示的に指定した public_id は上書きされない' do
    serie = Serie.create!(name: 'テスト作品2', public_id: 'MyFixedPublicId1')
    assert_equal 'MyFixedPublicId1', serie.public_id
    serie.update!(name: 'テスト作品2改')
    assert_equal 'MyFixedPublicId1', serie.reload.public_id
  end

  test '重複した public_id はバリデーションエラーになる' do
    existing = series(:one)
    serie = Serie.new(name: '重複テスト', public_id: existing.public_id)
    assert_not serie.valid?
    assert_includes serie.errors.attribute_names, :public_id
  end

  test 'to_param が public_id を返す' do
    serie = series(:one)
    assert_equal serie.public_id, serie.to_param
  end

  test '英数字以外を含む public_id はバリデーションエラーになる' do
    serie = Serie.new(name: '不正な形式', public_id: 'invalid-id!')
    assert_not serie.valid?
    assert_includes serie.errors.attribute_names, :public_id
  end
end
