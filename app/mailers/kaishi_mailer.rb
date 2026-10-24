class KaishiMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.kaishi_mailer.2014_kojin_ranking.subject
  #
  def kaishi2014_kojin_ranking(user, mail_address)
    @user = user
    attachments["#{user.name}.png"] = {
      content: File.read("tmp/kaishi2014/#{user.name}.png", mode: 'rb'),
      transfer_encoding: :binary
    }

    mail to: mail_address, subject: '【本日12時まで】個人ランキングページの確認'
  end

  def kaishi2014_kojin_ranking2(user, mail_address)
    @user = user
    attachments["#{user.name}.png"] = {
      content: File.read("tmp/kaishi2014/#{user.name}.png", mode: 'rb'),
      transfer_encoding: :binary
    }

    mail to: mail_address, subject: '個人ランキングページ最終'
  end
end
