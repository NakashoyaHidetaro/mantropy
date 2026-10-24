# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  EMAIL_DOMAIN = 'mail.mantropy.net'
  EMAIL_FROM = "no-reply@#{EMAIL_DOMAIN}".freeze
  default from: EMAIL_FROM
  layout 'mailer'
end
