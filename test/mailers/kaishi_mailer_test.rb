# frozen_string_literal: true

require 'test_helper'

class KaishiMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one)
    @png_path = Rails.root.join("tmp/kaishi2014/#{@user.name}.png")
    FileUtils.mkdir_p(@png_path.dirname)
    File.binwrite(@png_path, 'dummy')
  end

  teardown do
    FileUtils.rm_f(@png_path)
  end

  test 'mailer レイアウトで本文が組み立てられ、no-reply から添付付きで送信される' do
    mail = KaishiMailer.kaishi2014_kojin_ranking(@user, 'to@example.com')

    assert_emails 1 do
      mail.deliver_now
    end
    assert_equal [ApplicationMailer::EMAIL_FROM], mail.from
    assert_equal ['to@example.com'], mail.to
    assert_includes mail.text_part.body.to_s, "#{@user.name}さん"
    assert_equal ["#{@user.name}.png"], mail.attachments.map(&:filename)
  end
end
