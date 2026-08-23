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

  test 'recent_user_posts は include_board: true なら内部掲示板の書き込みも含む' do
    user = users(:one)
    comic_post = create_comic_post(user)
    ids = PostTimeline.recent_user_posts(user, include_board: true).map(&:id)
    assert_includes ids, comic_post.id
    assert_includes ids, posts(:one).id
  end

  test 'recent_user_posts は include_board: false なら漫画コメントのみ返す' do
    user = users(:one)
    comic_post = create_comic_post(user)
    ids = PostTimeline.recent_user_posts(user, include_board: false).map(&:id)
    assert_equal [comic_post.id], ids
  end

  test 'recent_user_posts は件数上限を超えない' do
    user = users(:one)
    (PostTimeline::RECENT_USER_POSTS_LIMIT + 2).times { create_comic_post(user) }
    posts = PostTimeline.recent_user_posts(user, include_board: true)
    assert_equal PostTimeline::RECENT_USER_POSTS_LIMIT, posts.size
  end

  test 'recent_user_posts は新しい順に並ぶ' do
    user = users(:one)
    3.times { create_comic_post(user) }
    ids = PostTimeline.recent_user_posts(user, include_board: true).map(&:id)
    assert_equal ids.sort.reverse, ids
  end

  test 'board_post? はタイトルのあるトピックのポストで真を返す' do
    assert PostTimeline.board_post?(posts(:one))
  end

  test 'board_post? はタイトルのないトピック（漫画）のポストで偽を返す' do
    assert_not PostTimeline.board_post?(create_comic_post(users(:one)))
  end

  test 'author_name_for は会員投稿ではユーザー名を返す' do
    post = posts(:one)
    # users fixture は joined / entered が空でバリデーションを通らないため、属性だけ差し替える
    post.user.name = '会員ユーザー'
    post.user.save!(validate: false)
    assert_equal '会員ユーザー', PostTimeline.author_name_for(post.reload)
  end

  test 'author_name_for は非会員投稿では name カラムを返す' do
    post = posts(:one)
    post.update!(user: nil, name: '名無しさん')
    assert_equal '名無しさん', PostTimeline.author_name_for(post)
  end

  private

  # 漫画へのコメント（title が nil のトピック + Serie）を作る
  def create_comic_post(user)
    topic = Topic.create!(title: nil)
    Serie.create!(name: "漫画#{topic.id}", topic: topic)
    Post.create!(content: '漫画へのコメント', topic: topic, user: user)
  end
end
