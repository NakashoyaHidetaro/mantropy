# SendGrid の SMTP リレー経由で送信する(本番のみ。開発は letter_opener、テストは :test)
ActionMailer::Base.delivery_method = :smtp if Rails.env.production?
ActionMailer::Base.smtp_settings = {
  user_name: 'apikey',
  password: ENV.fetch('SENDGRID_API_KEY', nil),
  domain: 'mail.mantropy.net',
  address: 'smtp.sendgrid.net',
  port: 587,
  authentication: :plain,
  enable_starttls_auto: true
}
