# 漫画へのコメントと内部掲示板スレッドのコメントを区別せず、
# 全 Post を新しい順に並べたタイムラインを組み立てる。
module PostTimeline
  class << self
    # タイムラインに表示するポストを新しい順（id 降順）でページングして返す。
    # 表示時に投稿者名・所属トピック名・漫画名を引くため、まとめて eager load しておく。
    def recent_posts(page: nil)
      Post.includes(:user, topic: :serie).order(id: :desc).page(page)
    end

    # ポストの所属先の表示名。内部掲示板スレッドはタイトル、漫画（title が nil）は漫画名を使う。
    def title_for(post)
      post.topic&.title.presence || post.topic&.serie&.name
    end

    # 投稿者の表示名。会員投稿は User の名前、非会員投稿は name カラムを使う。
    def author_name_for(post)
      post.user&.name.presence || post.name
    end
  end
end
