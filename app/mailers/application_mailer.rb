# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'no-replay@mail.mantropy.com'
  layout 'mailer'
end
