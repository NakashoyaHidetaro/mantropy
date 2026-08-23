class Member::UsersController < Member::Base
  skip_before_action :authenticate_user!, only: %i[new create]
  before_action :set_user, only: %i[edit update destroy]

  def new
    @user = User.new
  end

  def edit; end

  def create
    if current_user
      redirect_to(user_path(current_user.name), notice: '一つのログイン情報に一つを超えるユーザー情報は登録できません')
      return
    end

    @user = User.new(user_params)
    current_userauth.user = @user

    if @user.save
      current_userauth.save!
      redirect_to(user_path(@user.name), notice: 'User was successfully created.')
    else
      render action: 'new'
    end
  end

  def update
    unless @user.id == current_user.id
      redirect_to(user_path(current_user.name), notice: '他のユーザーは編集できません')
      return
    end

    @user.name.gsub!(%r{[./]}, '')
    # params[:user].each{|k,v| params[:user][k].gsub!(/\/\./, "") if k == :name}

    if @user.update(user_params)
      redirect_to(user_path(@user.name), notice: 'User was successfully updated.')
    else
      render action: 'edit'
    end
  end

  def destroy
    @user.destroy

    redirect_to(users_path)
  end

  private

  def set_user
    # member側もURLには内部IDではなく name を使う
    @user = User.find_by!(name: params.expect(:name))
  end

  def user_params
    params.expect(
      user: %i[name
               realname
               pcmail
               mbmail
               twitter
               url
               publicabout
               privateabout
               joined
               entered]
    )
  end
end
