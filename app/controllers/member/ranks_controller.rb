class Member::RanksController < Member::Base
  before_action :set_rank, only: %i[destroy]

  def create
    params[:rank][:rank].tr!('０-９', '0-9')
    @rank = Rank.new(rank_params)
    @rank.user_id = current_user.id

    add_magazine_placement

    unless Ranking.find(rank_params[:ranking_id]).registerable?
      redirect_to(user_path(current_user.name), notice: 'ランキングの変更はできません')
      return
    end

    save_rank
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

  # 順位登録と同時に、指定されていれば掲載誌もシリーズへ追加する。
  # 雑誌が特定できなかった場合は掲載誌の追加だけを見送り、順位の登録は続行する。
  def add_magazine_placement
    MagazinePlacement.add!(Serie.find(@rank.serie_id),
                           magazine_name: params[:magazine_name],
                           magazine_id: params[:magazine_id],
                           placed: params[:magazine_placed])
  rescue MagazinePlacement::MagazineNotFound
    nil
  end

  # すでに同じランキング・同じ順位の登録があれば上書きする。
  def save_rank
    msg = '登録しました。'
    if (existing = Rank.find_by(user_id: current_user.id, rank: rank_params[:rank],
                                ranking_id: rank_params[:ranking_id]))
      msg = '上書きしました。'
      @rank = existing
      @rank.serie_id = rank_params[:serie_id]
    end

    if @rank.save
      redirect_to(user_path(current_user.name), notice: "#{@rank.serie.name} に #{@rank.rank} 位を#{msg}")
    else
      redirect_to(@rank.serie, alert: "順位を登録できませんでした: #{@rank.errors.full_messages.join('、')}")
    end
  end

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
