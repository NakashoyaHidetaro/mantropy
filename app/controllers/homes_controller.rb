class HomesController < ApplicationController
  def index
    @content = HikiDoc.to_html(Wiki.where(name: 'top').order(created_at: :desc).limit(1)[0]&.content || '')
  end

  def robots
    respond_to do |format|
      format.text { render plain: '' }
    end
  end
end
