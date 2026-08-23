class Member::HomesController < Member::Base
  def index
    @wiki = Wiki.where(name: 'logged_in').order(created_at: :desc).limit(1).first
    @wikis = Wiki.where(name: @wiki&.name).order(created_at: :desc)
  end
end
