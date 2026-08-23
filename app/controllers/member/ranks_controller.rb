class Member::RanksController < Member::Base
  before_action :set_rank, only: %i[destroy]

  def create # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/PerceivedComplexity
    params[:rank][:rank].tr!('０-９', '0-9')
    @rank = Rank.new(rank_params)
    @rank.user_id = current_user.id
    s = Serie.find(@rank.serie_id)

    magazine_name = params[:magazine_name].strip
    if !magazine_name.empty? && Magazine.find_by(name: magazine_name).nil?
      magazine = Magazine.new
      magazine.name = magazine_name
      magazine.publisher = s.books.first && s.books.first.publisher
    else
      magazine = Magazine.find_by(name: magazine_name) || Magazine.find_by(id: params[:magazine_id])
    end
    if magazine
      placed = params[:magazine_placed].strip
      if s.magazines_series.where(magazine_id: magazine.id, placed:).empty?
        ms = MagazinesSerie.new
        ms.magazine = magazine
        ms.placed = placed
        ms.serie = s
        ms.save!
      end
    end

    unless Ranking.find(rank_params[:ranking_id]).registerable?
      redirect_to(user_path(current_user.name), notice: 'ランキングの変更はできません')
      return
    end

    msg = nil
    unless (r = Rank.where(user_id: current_user.id, rank: rank_params[:rank],
                           ranking_id: rank_params[:ranking_id])).empty?
      msg = '上書きしました。'
      @rank = r[0]
      @rank.serie_id = rank_params[:serie_id]
    end
    Rails.logger.debug @rank

    if @rank.save
      redirect_to(user_path(current_user.name),
                  notice: "#{@rank.serie.name} に #{@rank.rank} 位を#{msg || '登録しました。'}")
    else
      redirect_to(@rank.serie, notice: '失敗。ランク登録に合わない情報が混じった気がする')
    end
  end

  def destroy
    if @rank.user_id == current_user.id && @rank.ranking.registerable?
      @rank.destroy
      redirect_to(user_path(current_user.name))
    else
      redirect_to user_path(@rank.user.name), alert: 'あなたはこのランキングデータのユーザーでないか、またはこのランキングデータは修正できないものです'
    end
  end

  private

  def set_rank
    @rank = Rank.find(params[:id])
  end

  def rank_params
    params.expect(
      rank: %i[rank
               score
               ranking_id
               serie_id]
    )
  end
end
