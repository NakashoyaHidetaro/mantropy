class Member::SeriesController < Member::Base
  before_action :set_serie, only: %i[edit update destroy]

  @title = 'シリーズ'

  def index
    @title = 'シリーズ一覧'
    @series = Serie.order(id: :desc).page(params[:page])
  end

  def new
    @serie = (params[:id] ? Serie.find(params[:id]) : Serie.new)
    @serie_new = params[:id] || true
  end

  def edit
    @rankings = Ranking.where(is_registerable: true)
  end

  def create # rubocop:disable Metrics/AbcSize
    @serie = Serie.new(serie_params)

    a = Author.find_by(id: params[:author_id]) || Author.find_by(name: params[:author_name].strip)
    unless a
      a = Author.new
      a.name = params[:author_name].strip
      a.save!
    end
    @serie.authors << a

    m = Magazine.find_by(id: params[:magazine_id]) || Magazine.find_by(name: params[:magazine_name].strip)
    unless m
      m = Magazine.new
      m.name = params[:magazine_name].strip
      m.publisher = params[:magazine_publisher].strip
      m.save!
    end
    @serie.magazines << m if m

    params[:book_ids]&.each do |bid|
      @serie.books << Book.find(bid)
    end

    if @serie.save
      redirect_to(serie_path(@serie), notice: 'Serie was successfully created.')
    else
      render action: 'new'
    end
  end

  def update
    if @serie.update(serie_params)
      redirect_to(@serie, notice: 'Serie was successfully updated.')
    else
      render action: 'edit'
    end
  end

  def destroy
    @serie.destroy

    redirect_to(series_url)
  end

  # 不要疑惑
  def remove_duplications
    order_by = params[:order_by]&.gsub('_', '.') || 'authors.name'
    @series = Serie.select(
      'DISTINCT series.*'
    ).includes(
      :ranks, :authors
    ).where(
      ranks: { ranking_id: params[:ranking_id] }
    ).order(
      order_by
    ).page(
      params[:page]
    ).per(1000)
  end

  private

  def set_serie
    # member側もURLには内部IDではなく public_id を使う
    @serie = Serie.find_by!(public_id: params.expect(:public_id))
  end

  def serie_params
    params.expect(
      serie: %i[author_name
                magazine_name
                name]
    )
  end
end
