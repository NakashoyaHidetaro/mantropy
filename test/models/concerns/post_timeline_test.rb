require 'test_helper'

class PostTimelineTest < ActiveSupport::TestCase
  test 'recent_posts は全ポストを新しい順で返す' do
    posts = PostTimeline.recent_posts
    assert_equal Post.count, posts.total_count
    assert_equal Post.order(id: :desc).pluck(:id), posts.map(&:id)
  end

  test 'recent_posts はページングされる' do
    posts = PostTimeline.recent_posts(page: 1)
    assert_respond_to posts, :total_pages
    assert_equal 1, posts.current_page
  end

  test 'title_for はタイトルのあるトピックではタイトルを返す' do
    post = posts(:one)
    post.topic.update!(title: '内部掲示板スレッド')
    assert_equal '内部掲示板スレッド', PostTimeline.title_for(post.reload)
  end

  test 'title_for はタイトルのないトピックでは漫画名を返す' do
    post = posts(:one)
    post.topic.update!(title: nil)
    series(:one).update!(topic: post.topic)
    assert_equal 'MySerieOne', PostTimeline.title_for(post.reload)
  end

  test 'author_name_for は会員投稿ではユーザー名を返す' do
    post = posts(:one)
    post.user.update!(name: '会員ユーザー')
    assert_equal '会員ユーザー', PostTimeline.author_name_for(post.reload)
  end

  test 'author_name_for は非会員投稿では name カラムを返す' do
    post = posts(:one)
    post.update!(user: nil, name: '名無しさん')
    assert_equal '名無しさん', PostTimeline.author_name_for(post)
  end
end
