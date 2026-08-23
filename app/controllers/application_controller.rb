class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user, :complete_ranking

  private

  def complete_ranking(ranking, user = current_user)
    user && user.ranks.where(ranking_id: ranking.id).map do |r|
      (r.serie ? r.rank : 0)
    end.sort == ((ranking.scope_min)..(ranking.scope_max)).to_a
  end

  def current_user
    current_userauth&.user
  end

  def after_sign_in_path_for(_resource)
    member_root_path
  end

  def render_with_encoding(*options)
    if options[-1].is_a?(Hash) && (encoding = options[-1][:encoding])
      headers['Content-Disposition'] = 'Content-Disposition: attachment;'
      headers['Content-Type'] = "text/csv; charset=#{encoding}"
      render_without_encoding text: render_to_string.encode(encoding, invalid: :replace, undef: :replace)
    end
  end
  # alias_method_chain :render, :encoding

  def registerable_rankings
    Ranking.where(is_registerable: true)
  end

  def registering_rankings
    if registerable_rankings.empty?
      []
    else
      Ranking.where(['name LIKE ?',
                     "#{registerable_rankings.last.name[0...4]}%"]).order(:id)
    end
  end
end
