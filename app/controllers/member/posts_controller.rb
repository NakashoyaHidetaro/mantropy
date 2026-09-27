class Member::PostsController < Member::Base
  def index
    @posts = PostTimeline.recent_posts(page: params[:page])
  end

  def create
    @post = Post.new(post_params)
    @post.topic_id = params[:topic_id]
    topic = @post.topic
    redirect_path = (topic.title ? member_topic_show_path(topic) : serie_path(Serie.find_by(topic_id: topic.id)))
    begin
      Post.transaction do
        @post.user = current_user
        @post.order = Post.where(topic_id: @post.topic_id).count + 1
        @post.save!
        unless /sage/ =~ params[:post][:email]
          topic.updated_at = Time.zone.now
          topic.save!
        end
      end
      redirect_to(redirect_path, notice: '書き込みに成功しました')
    rescue ActiveRecord::RecordInvalid => e
      redirect_to(redirect_path, alert: "書き込みできませんでした: #{e.record.errors.full_messages.join('、')}")
    end
  end

  private

  def post_params
    params.expect(
      post: %i[name
               email
               order
               content
               topic
               user]
    )
  end
end
