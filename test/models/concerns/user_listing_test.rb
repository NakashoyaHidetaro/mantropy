require 'test_helper'

class UserListingTest < ActiveSupport::TestCase
  test '1年以内にrankを提出したユーザーはactive_usersに含まれる' do
    # fixture の ranks は created_at 未指定なので現在時刻扱いになる
    assert_includes UserListing.active_users, users(:one)
  end

  test '登録6ヶ月以内のユーザーはactive_usersに含まれる' do
    newcomer = User.create!(
      name: 'Newcomer', realname: '新人', mbmail: 'new@example.com',
      joined: '2026', entered: '2026'
    )
    assert_includes UserListing.active_users, newcomer
  end

  test '2年前登録でrank未提出のユーザーはactive_usersに含まれない' do
    assert_not_includes UserListing.active_users, users(:old_member)
  end

  test '2年前登録でrank未提出のユーザーはold_usersに含まれる' do
    assert_includes UserListing.old_users, users(:old_member)
  end

  test 'old_usersは全ユーザーからactive_usersを除いたものになる' do
    active = UserListing.active_users
    old = UserListing.old_users(active)
    assert_empty(old & active)
    assert_equal User.count, (old + active).uniq.size
  end

  test '登録が6ヶ月より前でも1年以内にrankを提出していればactive_usersに含まれる' do
    users(:old_member).update!(created_at: 2.years.ago)
    Rank.create!(rank: 1, score: 1, ranking: rankings(:kojin2014), user: users(:old_member), serie: series(:one))
    assert_includes UserListing.active_users, users(:old_member)
  end

  test '1年より前のrankしか持たないユーザーはactive_usersに含まれない' do
    rank = Rank.create!(rank: 1, score: 1, ranking: rankings(:kojin2014), user: users(:old_member), serie: series(:one))
    rank.update_column(:created_at, 2.years.ago) # rubocop:disable Rails/SkipsModelValidations
    assert_not_includes UserListing.active_users, users(:old_member)
  end
end
