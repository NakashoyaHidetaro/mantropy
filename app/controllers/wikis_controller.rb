class WikisController < ApplicationController
  def show
    @wiki = nil
    @wiki = if params[:id]
              Wiki.find(params[:id])
            else
              Wiki.where(name: params[:name]).order(created_at: :desc).limit(1).first
            end

    if @wiki.nil?
      redirect_to root_path, alert: '該当するWikiページがありません'
    elsif !current_user && Wiki.where(name: @wiki.name,
                                      created_at: Wiki.where(name: @wiki.name).maximum(:created_at))[0].is_private
      redirect_to root_path, alert: 'このWikiページはプライベートモードです。'
    else
      @wikis = Wiki.where(name: @wiki.name).order(created_at: :desc)
    end
  end
end
