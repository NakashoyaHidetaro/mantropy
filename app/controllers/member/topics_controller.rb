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
    @topic = Topic.new(topic_params)
    @topic.appear = 1
    if @topic.title.blank?
      # Topic モデル自体は題名なしも許す(シリーズ掲示板用)ため、ここで入力を確認する
      redirect_to(member_topics_path, alert: 'スレッドの題名を入力してください')
      return
    end

    begin
      Topic.transaction do
        @topic.save!
        Post.create!(content: params[:content], email: params[:email],
                     user: current_user, order: 1, topic: @topic)
      end
      redirect_to(member_topics_path, notice: 'スレッド作成と書き込みに成功しました。')
    rescue ActiveRecord::RecordInvalid => e
      redirect_to(member_topics_path, alert: "スレッドを作成できませんでした: #{e.record.errors.full_messages.join('、')}")
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
