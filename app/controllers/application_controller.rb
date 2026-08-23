class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user, :complete_ranking, :member_list_downloadable?

  private

  # ビューからも参照される helper_method のため名前は据え置く
  def complete_ranking(ranking, user = current_user) # rubocop:disable Naming/PredicateMethod
    RankAggregation.complete_ranking?(ranking, user)
  end

  # メンバー一覧の CSV / JSON をダウンロードできるか
  def member_list_downloadable?(registering_rankings = nil)
    RankingSubmission.member_list_downloadable?(current_user, registering_rankings)
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
    Ranking.registerable
  end

  def registering_rankings
    return [] if registerable_rankings.empty?

    Ranking.same_year_as(registerable_rankings.last).order(:id)
  end
end
