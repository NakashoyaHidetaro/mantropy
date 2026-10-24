# frozen_string_literal: true

require 'test_helper'

class DeviseMailerTest < ActionMailer::TestCase
  test 'パスワードリセットメールは no-reply@mail.mantropy.net から送信される' do
    userauth = userauths(:one)

    assert_emails 1 do
      userauth.send_reset_password_instructions
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ApplicationMailer::EMAIL_FROM], mail.from
    assert_equal ['no-reply@mail.mantropy.net'], mail.from
    assert_equal [userauth.email], mail.to
  end
end
