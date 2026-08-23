class Member::TopicsController < Member::Base
  before_action :set_topic, only: %i[show edit update]

  def index
    @topics = Topic.where(appear: 1).order(updated_at: :desc, id: :desc)
  end

  def show
    redirect_to serie_path(Serie.find_by(topic_id: @topic.id)) if @topic.title.nil?
  end

  def new
    @topic = Topic.new
  end

  def edit; end

  def create
    post = Post.new
    begin
      Topic.transaction do
        @topic = Topic.new(topic_params)
        @topic.appear = 1
        raise if @topic.title == '' || @topic.title.nil?

        @topic.save!

        post = Post.new
        post.content = params[:content]
        post.email = params[:email]
        post.user = current_user
        post.order = 1
        post.topic = @topic
        post.save!
      end
      redirect_to(member_topics_path, notice: 'スレッド作成と書き込みに成功しました。')
    rescue StandardError
      redirect_to(member_topics_path, alert: '何かおかしいで。')
    end
  end

  def update
    if @topic.update(topic_params)
      redirect_to(member_topic_show_path(@topic), notice: 'Topic was successfully updated.')
    else
      render action: 'edit'
    end
  end

  private

  def set_topic
    @topic = Topic.find(params[:id])
  end

  def topic_params
    params.expect(
      topic: %i[appear
                title]
    )
  end
end
