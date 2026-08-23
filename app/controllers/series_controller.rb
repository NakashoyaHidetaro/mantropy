class SeriesController < ApplicationController
  def index
    @str = params[:str]
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

    @series = SerieSearch.search(@str, page: params[:page])

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

    @ranks = @serie.finished_ranks
    @serie.ensure_topic!

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
