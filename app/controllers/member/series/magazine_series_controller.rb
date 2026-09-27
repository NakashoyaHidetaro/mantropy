class Member::Series::MagazineSeriesController < Member::Series::Base
  def update
    case params[:mode]
    when 'remove'
      @serie.magazines_series.delete(MagazinesSerie.find(params[:magazines_serie_id]))
    when 'add'
      # バリデーション失敗時は Member::Base の rescue_from が元の画面へエラーを表示して差し戻す。
      MagazinePlacement.add!(@serie,
                             magazine_name: params[:magazine_name],
                             magazine_id: params[:magazine_id],
                             placed: params[:magazine_placed])
    end
    redirect_to edit_member_serie_path(@serie)
  rescue MagazinePlacement::MagazineNotFound
    redirect_to edit_member_serie_path(@serie), alert: '雑誌を選択するか、雑誌名を入力してください'
  end
end
