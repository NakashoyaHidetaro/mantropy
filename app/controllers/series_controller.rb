class SeriesController < ApplicationController
  @title = 'シリーズ'

  def index # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/PerceivedComplexity
    @str = params[:str]
    @title = "#{@str} の検索結果"
    if @str.blank?
      redirect_to root_path, notice: '検索ワードを指定してください'
      return
    end

    if params[:scope] =~ /^rakuten/ && current_user
      begin
        RakutenSearchService.search_and_store(@str)
      rescue StandardError => e
        flash.now[:alert] = e
        raise e if Rails.env.development?
      end
    end

    # サーチワードを空白で分割してor検索
    search_strs = @str.strip.split(/[\s　]/).compact_blank

    # シリーズで名前検索
    series = Serie.none
    search_strs.each.with_index do |s, i|
      series = if i.zero?
                 Serie.where('name LIKE ?', "%#{s}%")
               else
                 series.or(series.where('name_kana LIKE ?', "%#{s}%"))
               end
    end

    # 著者で名前検索
    authors = Author.none
    search_strs.each.with_index do |s, i|
      authors = if i.zero?
                  Author.where('name LIKE ?', "%#{s}%")
                else
                  authors.or(series.where('name_kana LIKE ?', "%#{s}%"))
                end
    end

    # 著者名で引っかかるときはその著者の持っているシリーズを含める
    if authors.exists?
      serie_ids = AuthorsSerie.where(author_id: authors.pluck(:id)).pluck(:serie_id)
      series = series.or(Serie.where(id: serie_ids))
    end

    # ページネーション
    @series = series.page(params[:page]).order(id: :desc)

    if @series.one?
      # 結果が1件の場合はそのシリーズの詳細ページにリダイレクト
      redirect_to serie_path(@series[0])
    else
      render 'index'
    end
  end

  def show
    @serie = Serie.find_by(public_id: params.expect(:public_id))
    raise ActiveRecord::RecordNotFound if @serie.blank?

    @title = "#{@serie.name} のシリーズ情報"
    # rubocop:disable Layout/LineLength
    # @similar_series = Serie.find_by_sql("SELECT s.* FROM series s INNER JOIN (SELECT r1.serie_id, COUNT(*) AS similarity FROM ranks r1 INNER JOIN ranks r2 ON r1.user_id=r2.user_id WHERE r2.serie_id=#{@serie.id} GROUP BY r1.serie_id ORDER BY similarity DESC, SUM(r1.score) DESC) r ON r.serie_id=s.id WHERE s.id!=#{@serie.id} LIMIT 4")
    # rubocop:enable Layout/LineLength
    # @ranks = @serie.ranks.where(:ranking_id => [1, 2, 3, 4]).order("ranking_id DESC, rank")
    ranking_ids = Ranking.where('is_registerable IS NULL OR is_registerable = FALSE')
    @ranks = @serie.ranks.where(ranking_id: ranking_ids).order(ranking_id: :desc, rank: :asc)

    unless @serie.topic
      topic = Topic.new
      topic.save!
      @serie.topic = topic
      @serie.save!
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @serie }
    end
  end

  # 旧URL（/:name/series/:id, /series/:id）からの恒久リダイレクト
  def legacy_show
    serie = Serie.find_by(id: params.expect(:id))
    raise ActiveRecord::RecordNotFound if serie.blank?

    redirect_to serie_path(serie), status: :moved_permanently
  end
end
