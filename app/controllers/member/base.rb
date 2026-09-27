class Member::Base < ApplicationController
  before_action :authenticate_userauth!
  before_action :authenticate_user!

  # 専用のフォーム画面を持たない画面(一覧や他リソースの詳細)からの POST では、
  # バリデーション失敗を 500 にせず、元の画面へエラー内容つきで戻す。
  rescue_from ActiveRecord::RecordInvalid, with: :redirect_back_with_record_errors

  private

  def authenticate_user!
    redirect_to new_member_user_path, notice: 'ユーザー情報を登録してください' if current_user.nil?
  end

  def redirect_back_with_record_errors(exception)
    redirect_back_or_to(member_root_path, alert: record_error_message(exception.record))
  end

  # エラーメッセージを日本語の読点で連結する。メッセージが取れない場合は汎用の文言にする。
  def record_error_message(record)
    messages = record&.errors&.full_messages || []
    messages.empty? ? '保存できませんでした' : messages.join('、')
  end

  def admin_basic_authentication
    authenticate_or_request_with_http_basic('Development Authentication') do |user, password|
      user == ENV['DIGEST_USER'] && password == ENV['DIGEST_PASS']
    end
  end
end
