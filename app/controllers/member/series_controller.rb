class Member::SeriesController < Member::Base
  before_action :set_serie, only: %i[edit update]

  def new
    @serie = (params[:id] ? Serie.find(params[:id]) : Serie.new)
    @serie_new = params[:id] || true
  end

  def edit
    @rankings = Ranking.registerable
  end

  def create
    @serie = Serie.new(serie_params)

    author = find_or_create_author
    return render_new_with_errors(author, :author_name) if author.errors.any?

    magazine = find_or_create_magazine
    return render_new_with_errors(magazine, :magazine_name) if magazine.errors.any?

    @serie.authors << author
    @serie.magazines << magazine
    params[:book_ids]&.each { |bid| @serie.books << Book.find(bid) }

    if @serie.save
      redirect_to(serie_path(@serie), notice: 'シリーズを登録しました')
    else
      render_new
    end
  end

  def update
    if @serie.update(serie_params)
      redirect_to(@serie, notice: 'シリーズを更新しました')
    else
      render action: 'edit', status: :unprocessable_content
    end
  end

  private

  # 作者名(またはID)から作者を探し、無ければ作成する。
  # 作成に失敗した場合はエラーを持ったままの未保存レコードを返す。
  def find_or_create_author
    name = params[:author_name].to_s.strip
    author = Author.find_by(id: params[:author_id]) || Author.find_by(name:)
    return author if author

    Author.new(name:).tap(&:save)
  end

  # 雑誌名(またはID)から雑誌を探し、無ければ作成する。
  def find_or_create_magazine
    name = params[:magazine_name].to_s.strip
    magazine = Magazine.find_by(id: params[:magazine_id]) || Magazine.find_by(name:)
    return magazine if magazine

    Magazine.new(name:, publisher: params[:magazine_publisher].to_s.strip).tap(&:save)
  end

  # 作者・雑誌の作成に失敗した場合、そのエラーをシリーズ側に転記して new を再表示する。
  def render_new_with_errors(record, attribute)
    record.errors.full_messages.each { |message| @serie.errors.add(attribute, message) }
    render_new
  end

  def render_new
    @serie_new = true
    render action: 'new', status: :unprocessable_content
  end

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
