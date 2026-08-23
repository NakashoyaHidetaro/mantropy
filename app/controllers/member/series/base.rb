class Member::Series::Base < Member::Base
  before_action :set_serie

  private

  def set_serie
    # 親の member/series が param: :public_id のため、ネスト側は :serie_public_id を受け取る
    @serie = Serie.find_by!(public_id: params.expect(:serie_public_id))
  end
end
